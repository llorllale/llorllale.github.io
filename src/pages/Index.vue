<template>
    <Layout>
        <div class="content">
            <header class="header">
                <h1 v-html="$page.metaData.siteName" />
                <h2 v-html="$page.metaData.siteDescription" />
            </header>
            <section class="posts">
                <Posts v-for="edge in $page.allPost.edges" :key="edge.node.id" :post="edge.node" class="wow fadeInLeft"/>
            </section>
        </div>
    </Layout>
</template>

<script>
    import Posts from "@/components/Posts";
    export default {
        components: {
            Posts
        },
        metaInfo: {
            title: "A simple blog"
        }
    };
</script>

<page-query>
query {
    metaData {
        siteName
        siteDescription
    }
    allPost {
        totalCount
        edges {
            node {
                id
                title
                timeToRead
                excerpt
                date (format: "DD MMMM YYYY")
                path
            }
        }
    }
}
</page-query>

<style scoped>
    .content {
        background-color: white;
        /*max-width: 2000px;*/
        margin: 4rem auto;
        padding: 0 2em;
        text-align: justify;
        box-sizing: border-box;
        width: 100%;
        position: relative;
    }
    .header {
        font-family: "Fira Code";
        font-size: 35px;
        text-align: center;
        line-height: 20px;
        padding: 0.7em;
    }
    .header h2 {
        font-weight: 200;
        font-size: 35px;
    }
</style>