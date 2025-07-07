B4J=true
Group=Handlers
ModulesStructureVersion=1
Type=Class
Version=10.2
@EndOfDesignText@
'Handler class
Sub Class_Globals
	Private Request As ServletRequest
	Private Response As ServletResponse
	Private Method As String
	Private Elements() As String
	Private ElementKey As String
	Private ElementId As Int
End Sub

Public Sub Initialize
	
End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	Request = req
	Response = resp
	Method = Request.Method.ToUpperCase
	Dim FullElements() As String = WebApiUtils.GetUriElements(Request.RequestURI)
	Elements = WebApiUtils.CropElements(FullElements, 1) ' 1 For Index handler
	If ElementMatch("") Then
		If Main.app.MethodAvailable2(Method, "", Me) Then
			ShowIndexPage
			Return
		End If
	End If
	If ElementMatch("key") Then
		If Main.app.MethodAvailable2(Method, "/todo", Me) Then
			Select Method
				Case "POST"
					createTodo(Request.GetParameter("newTodo"))
					WebApiUtils.ReturnHtml(ReturnListItems, Response)
					Return
				Case "GET"
					WebApiUtils.ReturnHtml(ReturnListItems, Response)
					Return
			End Select
		End If
		WebApiUtils.ReturnHtml("<h1>405 Method Not Allowed</h1>", Response)
		Return
	End If
	If ElementMatch("key/id") Then
		Select ElementKey
			Case "todo"
				If Main.app.MethodAvailable2(Method, "/todo/*", Me) Then
					Select Method
						Case "PUT"
							updateTodo(ElementId)
						Case "DELETE"
							deleteTodo(ElementId)
					End Select
					WebApiUtils.ReturnHtml(ReturnListItems, Response)
					Return
				End If
				WebApiUtils.ReturnHtml("<h1>405 Method Not Allowed</h1>", Response)
				Return
		End Select
	End If
	WebApiUtils.ReturnHtmlPageNotFound(Response)
End Sub

Private Sub ElementMatch (Pattern As String) As Boolean
	Select Pattern
		Case ""
			If Elements.Length = 0 Then
				Return True
			End If
		Case "key"
			If Elements.Length = 1 Then
				ElementKey = Elements(0)
				Return True
			End If
		Case "key/id"
			If Elements.Length = 2 Then
				ElementKey = Elements(0)
				ElementId = Elements(1)
				Return True
			End If
	End Select
	Return False
End Sub

Private Sub ShowIndexPage
	Dim content As String = $"<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HTMX Todo</title>
    <script src="https://unpkg.com/htmx.org@1.9.10"
        integrity="sha384-D1Kt99CQMDuVetoL1lrYwg5t+9QdHe7NLX/SoJYkXDFfX37iInKRy5xLSi8nO7UC"
        crossorigin="anonymous"></script>
</head>

<body>

    <form hx-post="http://localhost:3000/todo" hx-target="#todo-list">
        <label for="newTodo">New Todo:</label>
        <input type="text" name="newTodo" id="newTodo" />
        <button type="submit">Submit</button>
    </form>

    <ol id="todo-list" hx-get="http://localhost:3000/todo" hx-trigger="load"><li>abc</li></ol>

</body>

</html>"$
	WebApiUtils.ReturnHTML(content, Response)
End Sub

Sub ReturnListItems As String
	Dim content As StringBuilder
	content.Initialize
	For Each todo As Map In readTodo
		Dim id As Int = todo.Get("id")
		Dim title As String = todo.Get("title")
		Dim completed As Boolean = todo.Get("completed")
		Log($"${id}: ${completed}"$) ' to verify value is updated
		content.Append($"<li>
      <input 
        type="checkbox"
        id="todo_${id}"
        ${IIf(completed, "checked", "")}
        hx-put="http://localhost:3000/todo/${id}"
        hx-trigger="click"
        hx-target="#todo-list"
      />
      <label for="todo_${id}">${title}</label>
      <button
        hx-delete="http://localhost:3000/todo/${id}"
        hx-trigger="click"
        hx-target="#todo-list"
      >❌</button>
    </li>"$)
	Next
	Log("---")
	Return content.ToString
End Sub

Sub createTodo (newTodo As String)
	Main.todos.Add(CreateMap("title": newTodo, "completed": False))
End Sub

Sub readTodo As List
	Return Main.todos.List
End Sub

Sub updateTodo (id As Int)
	Main.todos.Find(id).Put("completed", Not(Main.todos.Find(id).Get("completed").As(Boolean)))
End Sub

Sub deleteTodo (id As Int)
	Main.todos.Remove(Main.todos.IndexFromId(id))
End Sub