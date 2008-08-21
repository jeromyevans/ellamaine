<%@ page import="java.util.Calendar" %>
<html>
<head>
  <title>Ellamaine Repository</title>
</head>
<body>
<a href="page">Browse Pages</a><br/>
<a href="list?year=<%=Calendar.getInstance().get(Calendar.YEAR)%>&month=<%=Calendar.getInstance().get(Calendar.MONTH)+1%>&day=<%=Calendar.getInstance().get(Calendar.DATE)%>">List entries by date</a>
</body>
</html>