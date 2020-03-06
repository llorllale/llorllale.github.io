---
layout: post
title: 'Maven: error due to attempt to deploy "sources" artifact twice'
excerpt: Unable to get rid of the 400 error when running a build to deploy your artifact to a maven repository?
date: 2015-11-25
author: George Aristy
tags: 
modified_time: '2015-11-25T09:37:41.154-04:00'
blogger_id: tag:blogger.com,1999:blog-5903491164319093451.post-1623220361592153279
blogger_orig_url: http://llorllale.blogspot.com/2015/11/maven-error-due-to-attempt-to-deploy.html
---

Unable to get rid of the 400 error when running a build to deploy your artifact to a maven repository? Have you read about how the sources:jar goal is <a href="http://blog.peterlynch.ca/2010/05/maven-how-to-prevent-generate-sources.html" target="_blank">executed twice</a> and then tried <a href="http://stackoverflow.com/a/10794985" target="_blank">overriding</a> that behavior? Still not working?<br /><br />Well, if you're like me and you are blindly running your build from Netbeans, you might want to verify that you're not executing both the <a href="https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html#Lifecycle_Reference" target="_blank">install and deploy</a> goals. Run them separately and your artifact should be uploaded to your repo without issue. :)
