---
id: frontend.l1.html-css-js-roles
lang: en
track: frontend
level: 1
stage: 1
module: web-foundations
main_path: true
title: "Structure, look, behavior: HTML, CSS, JS"
duration_min: 12
skills: [frontend.web.languages]
prereqs: [foundation.l1.url-to-page, foundation.l1.http-request-response]
related: []
vocab: [html, css, javascript]
example_tag: stage-0
versions_used: []
content_version: 1
status: draft
---

## Before you start

- [[foundation.l1.url-to-page]] — you know the browser requests `http://localhost:8080/index.html` and receives the page's HTML as the response body.
- [[foundation.l1.http-request-response]] — you know a response has a status line, headers and a body.

## The situation

You have opened `http://localhost:8080/index.html` from the lab many times: a heading, a line of text, three links. Clicking a link asks Caddy for another address. Nothing on the page reacts in place: no menu opens, no message appears, nothing updates without a new request. A teammate asks for a small change: "Can the page show a short welcome message when someone clicks the heading, without loading anything new?" Which part of the page would you have to add, and why can the file you have not do it on its own?

## Core concepts

- **HTML** — the language that structures a page's content: headings, paragraphs, lists, links.
- **CSS** — the language that describes how that structure looks: color, size, spacing, layout.
- **JavaScript** — the language a browser runs to change a page after it has loaded, for example in answer to a click; often shortened to JS.
- element — one piece of structure in HTML, written as a tag such as `<h1>…</h1>` around its content.
- stylesheet — a separate CSS file that a page attaches with a `<link>` element.

## How it works

```mermaid
flowchart LR
  H[HTML: what is on the page] --> P[page on screen]
  C[CSS: how it looks] --> P
  J[JavaScript: what changes after loading] --> P
```

A web page is usually built from three languages, each with one job. **HTML** says what is there: this is a heading, this is a paragraph, this is a link to `/login.html`. It is structure and content, nothing more. The browser reads it top to bottom and builds the page from the elements it finds.

**CSS** says how that structure looks: the heading is dark blue, paragraphs have more space between lines, the links sit side by side. The same HTML can look completely different with different CSS attached. A page with no CSS of its own is not unstyled, though: browsers apply default styles, which is why a heading is still bigger and bold, and a link is still coloured and underlined.

**JavaScript** is the only one of the three that runs as a program in the browser. Without it, a page can still do what the browser has built in: follow a link to another address, change a colour while the pointer is over something, play an animation its CSS describes. What it cannot do is run your own logic in answer to a click: decide what should happen, fetch data, add a message to the page. That takes JavaScript, and it happens on the page already loaded, without asking the server for a whole new one.

## In the Đơn Hàng system

The lab's home page, served by Caddy since the HTTP lessons:

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

Everything here is HTML. The first lines say this is an HTML page in Vietnamese with UTF-8 text. `<head>` holds information about the page, such as its `<title>`, the text on the browser tab. `<body>` holds what you see: one `<h1>` heading, one `<p>` paragraph, and a `<ul>` list whose `<li>` items each wrap an `<a>` link. There is no `<style>` element and no `<link>` to a stylesheet, so no CSS of its own. There is no `<script>` element, so no JavaScript.

That is why the page looks and behaves the way it does. Its look is the browser's defaults. Its only reactions are the links, and each one asks Caddy for a different address. The teammate's welcome message would need JavaScript: some code, attached to the page with a `<script>` element, that runs when the heading is clicked and adds the message to what is on screen.

## Beginners often think…

- **"HTML alone can make a page interactive, the same way a button click can run code."** → Actually HTML only describes content, including buttons and links; it does not run your own code when they are clicked. A link in `www/index.html` works, but its "behaviour" is the browser loading a different address, not logic changing this page. You notice the difference when you want something on the page to change in answer to a click, and find there is nowhere in the HTML to say what should happen.
- **"CSS changes what content is there, not just how it looks."** → Actually CSS changes how the content looks: size, colour, position, even whether it is shown — but hidden content is still in the HTML. `www/index.html` has no CSS of its own, and its heading, text and links are all there. You notice this when the same page shows the same words with any CSS, or none, only looking different.

## Try it (3 minutes)

With the lab running:

1. Open `http://localhost:8080/index.html` and look at the heading and the links.
2. Open the page source (in most browsers, right-click → View page source, or Ctrl+U).
3. In the source, search (Ctrl+F) for `<style`, `<link` and `<script`.

Expected result: the heading is large and bold and the links are coloured and underlined, but the source contains none of the three searches — only the HTML shown above.

Where do the heading's size and the links' colour come from, if the page has no CSS of its own?

<details><summary>Suggested answer</summary>

From the browser's default styles. Browsers give headings, paragraphs and links a basic look when a page brings no CSS, which is why a page with no stylesheet still is not a wall of identical plain text.

</details>

## Connections

- [[foundation.l1.url-to-page]] — how the HTML reaches the browser in the first place.
- [[frontend.l1.the-dom]] — what the browser builds from the HTML, and what JavaScript actually changes.

## Five-line summary

1. HTML structures a page's content: headings, paragraphs, lists and links.
2. CSS describes how that structure looks; without CSS of its own, a page still gets the browser's default styles.
3. JavaScript is the only one of the three that runs as a program, changing a page after it has loaded.
4. `www/index.html` is HTML only: no `<style>`, no stylesheet `<link>`, no `<script>`.
5. A link in plain HTML loads another address; running your own logic on a click needs JavaScript.
