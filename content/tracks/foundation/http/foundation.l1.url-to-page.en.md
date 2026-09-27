---
id: foundation.l1.url-to-page
lang: en
track: foundation
level: 1
stage: 0
module: http
main_path: true
title: "From typing a URL to seeing the page"
duration_min: 12
skills: [foundation.http.message, foundation.net.dns]
prereqs: [foundation.l1.dns, foundation.l1.tcp-vs-udp, foundation.l1.tls-and-https]
related: [backend.l1.request-lifecycle, frontend.l1.browser-rendering]
vocab: [request, response]
example_tag: stage-0
versions_used: [http, tls, caddy]
content_version: 1
status: approved
approved_by: auto
reviewed_at: "2026-09-28T13:00:00+07:00"
---

## Before you start

- [[foundation.l1.dns]] — you know a name has to become an IP address first; here that lookup is step one of a longer chain.
- [[foundation.l1.tcp-vs-udp]] — you know a TCP connection is set up before any bytes flow, and that refused and timed out are different failures; that connection carries everything in this lesson.
- [[foundation.l1.tls-and-https]] — you know TLS is agreed on top of that connection; here it is the step between connecting and asking.

## The situation

You start the lab — the programs `scripts/up.sh` runs on your machine, with names and addresses of its own, so it behaves like a separate machine — and open `http://localhost:8080/index.html` in your browser; `localhost` is a name that always means the machine you are on, address `127.0.0.1`. The page appears at once. You then type `https://donhang.local:8443` and the browser stops with a message about the name. A day later a colleague says the site is slow, and you cannot say which part: the machine, the connection, or Caddy, the program serving the page. Pressing Enter feels like one action, so a failure feels like one failure. What actually happens between pressing Enter and the page appearing?

## Core concepts

- the chain — the fixed order of steps a browser runs for one address: find the address, open the connection, agree on encryption, ask, receive, draw.
- **request** — the message your browser sends to a server — the program listening on that port, Caddy in this lab — naming exactly one thing it wants.
- **response** — the message the server sends back, carrying that thing or the reason it is not coming; a request and its response make one exchange.
- the page's HTML — the text file the server sends for a page: tags (pieces written inside `<` and `>`) that describe the page and name the files it needs, such as styles (files that say how it should look), images and scripts (small programs the browser runs inside the page, which can send requests of their own).
- the network tab — a panel in the browser's developer tools (inspection panels built into the browser, opened from its menu) that lists the exchanges a page makes, one row each, with how long each took; open it before you reload so the rows appear.

## How it works

```mermaid
sequenceDiagram
  participant B as Browser
  participant R as DNS
  participant S as Server
  B->>R: which address does this name have?
  R-->>B: an IP address
  B->>S: open a connection to the port
  B->>S: agree on encryption (https only)
  B->>S: ask for one path
  S-->>B: send back the page
  B->>S: ask again for each file the page embeds
```

Your address carries three things: a scheme (`http` or `https`, before `://`), a host name and a port. The scheme decides whether encryption is used; with no port written the browser uses 80 for `http` and 443 for `https`, but the lab writes `8080` and `8443`.

Step one turns the host name into an IP address, usually by asking DNS, because a connection is opened to a number, not a name. In this lab, step two opens a TCP connection to that address and port. Step three, for `https` only, agrees on encryption. Only then does the browser send its request, naming one path: the part of the address after the host and port, such as `/index.html`. The server sends back one response, whose first line — `HTTP/1.1 200 OK` below — says how it went. After it comes the thing asked for, here the page's HTML.

The browser reads that HTML, asks for every file it embeds, and draws the page from what has arrived. Each file is another request and response, and a script on the page can send more requests after the page is drawn.

Each step fails on its own. A name with no address fails before any connection exists. A connection to a port with nothing listening is refused; one whose bytes never come back times out. An untrusted certificate — the server's proof of identity — stops things after connecting: the browser warns you and sends no request unless you continue past it. A server failure comes last: the response arrives, but it says the request did not go well. Wording differs between browsers, but the category — name, connection, certificate, server — usually tells you which step to look at first.

## In the Đơn Hàng system

The repository has one script that walks the chain, one command per step. The script re-runs itself inside the lab before doing anything, so `lab` — a name only the lab itself can look up — works for it even though it does not work for you.

```bash file=scripts/http/trace-request.sh tag=stage-0 lines=7-25
echo "1. turn the name into an address"
nslookup lab | grep -A1 '^Name:'

echo
echo "2. open a TCP connection to the port"
nc -z -w 3 localhost 8080 2>/dev/null && echo "   connected to port 8080"

echo
echo "3. agree on encryption (only on the HTTPS port)"
echo | openssl s_client -connect donhang.local:8443 2>/dev/null | grep -E '^ +Protocol +:'

echo
echo "4. send the request, read the response"
curl -sS -D - -o /dev/null http://localhost:8080/index.html

echo "5. one page, several requests"
for page in index.html login.html cached.html; do
  curl -sS -o /dev/null -w "   %{http_code} %{url_effective}\n" "http://localhost:8080/$page"
done
```

Each numbered `echo` names a step, and the command under it makes that step visible. An earlier line, not shown, stops the script at the first command that fails, so if step 1, 3 or 4 cannot complete, the last numbered line printed is that step. The lab passes your machine's port 8080 through to its own, so `localhost:8080` reaches the same Caddy from the script and from your browser.

- Step 1: `nslookup` looks up `lab` only to show a lookup happening; `grep -A1` keeps the `Name:` line and the line after it.
- Step 2: `nc -z -w 3` only connects, giving up after 3 seconds, and `2>/dev/null` hides its own messages. `&& echo` prints only when it connects, so a failure leaves the block empty and the script carries on to step 3.
- Step 3: `echo |` makes `openssl s_client` close right after the agreement. Only the HTTPS port runs encryption, hence `donhang.local:8443` instead of `localhost:8080`.
- Step 4: `-D -` prints what came back instead of the page, and `-o /dev/null` throws the page away. A response reporting a failure, such as `503`, does not stop the script.
- Step 5: `-w` prints how each exchange went and which address was asked for.

Each command resolves its name and connects on its own, so no step reuses the address step 1 printed.

```text output=true
1. turn the name into an address
Name:	lab
Address: 172.28.0.12

2. open a TCP connection to the port
   connected to port 8080

3. agree on encryption (only on the HTTPS port)
    Protocol  : TLSv1.3

4. send the request, read the response
HTTP/1.1 200 OK
...

5. one page, several requests
   200 http://localhost:8080/index.html
   200 http://localhost:8080/login.html
   200 http://localhost:8080/cached.html
```

`...` stands for further lines sent before the page, which the next lesson opens up. The name `lab` becomes an address, the port answers, the encrypted port reports `TLSv1.3`, and only then does an exchange happen. `200` is how that first line says it went well, so step 5's three lines are three successful exchanges. Step 5 asks for three pages by hand to show that each ask is its own exchange; the browser would not have asked for the other two.

```html file=www/index.html tag=stage-0 lines=1-16
<!doctype html>
<html lang="vi">
<head>
<meta charset="utf-8">
<title>Đơn Hàng</title>
</head>
<body>
<h1>Đơn Hàng</h1>
<p>Trang tĩnh của phòng lab stage-0.</p>
<ul>
<li><a href="/login.html">Đăng nhập</a></li>
<li><a href="/cached.html">Trang có cache</a></li>
<li><a href="/redirect">Chuyển hướng</a></li>
</ul>
</body>
</html>
```

Three `<a href=…>` lines point at other pages, but there is no `<img>` for an image, no `<link>` for a style file and no `<script>`, so this page gives the browser nothing to fetch on its own; the linked pages load when you click them. A page in a real product embeds many files, each another exchange and another row in the network tab, which is how you find the slow one.

## Beginners often think…

- **"Loading a page is one request."** → Actually the first exchange brings only the HTML; the browser then asks again for every file that HTML embeds, and again for any data the page fetches afterwards. You notice this when the network tab shows several rows for a page you opened once.
- **"If the page is slow, the server is slow."** → Actually the slow part can be the name lookup, the connection, the encryption agreement, or one late file among many, and the first three happen before the server starts producing the page. You notice this when the network tab shows one row still waiting while every other row finished in milliseconds.
- **"The site not opening means the server is down."** → Actually a step earlier in the chain can stop you first: in this lab the browser cannot find `donhang.local` until you add `127.0.0.1 donhang.local` to your machine's hosts file, a local list of name-to-address lines your machine usually checks before asking DNS. You notice this when step 3 of the script reaches that port while your browser insists the site does not exist. The lab lists `donhang.local` in its own hosts file.

## Try it (3 minutes)

1. With the lab running, run `scripts/http/trace-request.sh` from the repository and read the five numbered steps in order.
2. Open `http://localhost:8080/index.html` in your browser with the developer tools' network tab open, reload the page, and compare what you see there with step 5 of the script.

Expected result: the script prints one block per step and ends with three lines for three addresses. The network tab shows a row for `index.html`, possibly a second row for the small site icon browsers ask for on their own, and no row for `login.html` or `cached.html`, because the browser fetches a linked page only when you click it.

## Connections

- [[foundation.l1.http-request-response]] — the next lesson opens up step four of this chain: what a request and a response are made of.
- [[foundation.l1.dns]] — step one of this chain in full, including why an address you changed can survive for a while.
- [[backend.l1.request-lifecycle]] — the same chain from the other end: what the server does between receiving the request and writing the response.
- [[frontend.l1.browser-rendering]] — what happens after the responses arrive: how the browser turns those files into pixels.

## Five-line summary

1. Typing an address starts a fixed chain: resolve the name, connect, agree on encryption (https only), send a request, receive a response, fetch the rest.
2. A request names one thing and a response answers it; both travel over the connection the earlier steps set up.
3. Each step fails in its own way, so the error you are shown usually points at the step to look at first.
4. One page is many exchanges: the HTML first, then every file it embeds, then any data it asks for.
5. The network tab lists those exchanges row by row, which is how you find the slow one.
