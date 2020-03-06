// This is where project configuration and plugin options are located. 
// Learn more: https://gridsome.org/docs/config

// Changes here require a server restart.
// To restart press CTRL + C in terminal and run `gridsome develop`

module.exports = {
  siteName: "George Aristy",
  siteDescription: "Blog about software craftsmanship.",
  plugins: [
    {
      use: "@gridsome/source-filesystem",
      options: {
        baseDir: "./content/posts",
        path: "*.md",
        typeName: "Post",
        route: "/blog/:year/:month/:day/:title"
      }
    }
  ],
  transformers: {
    //Add markdown support to all file-system sources
    remark: {
      externalLinksTarget: "_blank",
      externalLinksRel: ["nofollow", "noopener", "noreferrer"],
      plugins: [
        "@gridsome/remark-prismjs"
      ],
      config: {
        footnotes: true
      }
    }
  },
}
