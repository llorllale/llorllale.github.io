<template>
    <main class="layout" role="main">
        <slot/>
        <div class="footer">
            <p>
                Built with
                <a class="link" href="//gridsome.org">Gridsome</a>
            </p>
        </div>
    </main>
</template>

<style>
    body {
        font-family: -apple-system, system-ui, BlinkMacSystemFont, "Segoe UI", Roboto,
        "Helvetica Neue", Arial, sans-serif;
        margin: 0;
        padding: 0;
        line-height: 1.5;
        min-height: 100vh;
        background-image:url(/assets/images/keyboard.jpeg); background-repeat: no-repeat; background-size: cover;
        background-attachment: fixed;
    }
    .layout {
        max-width: 760px;
        margin: 0 auto;
        padding-left: 20px;
        padding-right: 20px;
    }
    .footer {
        padding-top: calc(30em / 4);
        text-align: center;
        font-size: 1em;
    }
    .link {
        padding: 3px;
        color: #333;
        text-decoration: none;
        border: 2px solid yellowgreen;
    }
    blockquote {
        border-left: 4px solid
        darkgreen;
        padding-left: 15px;
        background-color: lightyellow;
    }
    code:not([class]) {
        background-color: #e8e8e8;
        font-family: monospace;
        border: 1px solid lightgrey;
        border-radius: 4px;
        padding: 0 5px;
    }
</style>
