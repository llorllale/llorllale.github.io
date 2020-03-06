<template>
    <Layout>
        <div class="post">
            <br>
            <g-link to="/" class="link">  &larr; Go Back</g-link>
            <div class="post-title">
                <h1>{{$page.post.title}}</h1>
                <p class="post-date"> {{ $page.post.date}} | {{$page.post.timeToRead}} min read</p>
            </div>
            <div class="post-content">
                <p v-html="$page.post.content" />
            </div>
        </div>
    </Layout>
</template>

<page-query>
query Post ($path: String!) {
    post: post (path: $path) {
        id
        title
        content
        date (format: "D MMMM YYYY")
        timeToRead
    }
}
</page-query>

<style>
    .post {
        background-color: white;
        padding: 0 2em;
        width: 100%;
    }
    .post-title {
        text-align: center;
        font-size: 1em;
        /*line-height: 10px;*/
        padding: 2em 0;
        font-family: sans-serif;
        font-weight: bold;
    }
    .post-date {
        font-size: 16px;
        font-weight: 400;
    }
    .post-content {
        font-size: 20px;
    }
    .footnotes {
        font-size: 16px;
        line-height: 1.5;
    }
</style>
