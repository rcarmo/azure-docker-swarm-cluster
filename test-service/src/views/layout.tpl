<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">

	<title>${hostname}</title>
	<meta name="description" content="Simple stateless demo app">

	<link href="minimal.css" rel="stylesheet">
</head>
<body>
<div class="container">
	<header>
		<a class="logo">Hostname: ${hostname}</a>
		<nav class="float-right">
			<ul>
				<li>${requests} local requests (${shared_count} global)</li>
				<li>${timestr}</li>
			</ul>
		</nav>
	</header>
	<div class="row">
		<div class="col-12">
			<h1>Stateless Demo App</h1>
			<hr>
			<p>This is a small stateless webapp for demoing load balancing. While each instance maintains a request count to demonstrate load sharing among instances, the count is not preserved if the app is restarted.</p>
            <h3>Endpoints</h3>
            <ul>
                <li><tt>/hostname</tt> to obtain the hostname (requests to this URL and to the homepage are counted)</li>
                <li><tt>/count</tt> to get the request count</li>
                <li><tt>/shared_count</tt> to get the shared request count</li>
                <li><tt>/reset</tt> to reset request and computation counters</li>
                <li><tt>/reset_shared</tt> to reset the shared request counter</li>
                <li><tt>/compute/100</tt> to perform a computation during 100ms (approximately)</li>
                <li><tt>/compute/100,200</tt> to perform a computation for a random interval between 100 and 200ms</li>
            </ul>
		</div>
	</div>
<hr>

<div class="row">
    <div class="col-6">
    	<div class="text-center">
	    	<h2>Server Environment</h2>
	    </div>
        <hr>
<%
from os import environ
%>
        <table class="table">
            <tr>
                <th scope="col">Variable Name</th>
                <th scope="col">Value</th>
            </tr>
% for k, v in sorted(list(environ.items())):
            <tr>
                <th scope="row">${k}</th>
                <td>${v}</td>
            </tr>
% endfor
    	</table><!-- table -->
    </div>
    <div class="col-6">
        <div class="text-center">
            <h2>Request Environment</h2>
        </div>
        <hr>
        <table class="table">
            <tr>
                <th scope="col">Variable Name</th>
                <th scope="col">Value</th>
            </tr>
% for k, v in sorted(list(request.args.items())):
            <tr>
                <th scope="row">${k}</th>
                <td>${v}</td>
            </tr>
% endfor
    	</table><!-- table -->
    </div>
    </div>

	<footer>
			<a href="https://github.com/rcarmo">@rcarmo</a> <a class="float-right" href="http://minimalcss.com">Minimal CSS</a>
	</footer><!-- footer -->
</div>
</body>
</html>
