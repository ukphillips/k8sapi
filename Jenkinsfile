#!/usr/bin/groovy
import java.text.SimpleDateFormat

podTemplate(label: 'jenkins-pipeline', containers: [
    containerTemplate(name: 'jnlp', image: 'jenkinsci/jnlp-slave:latest', args: '${computer.jnlpmac} ${computer.name}', workingDir: '/home/jenkins', resourceRequestCpu: '200m', resourceLimitCpu: '200m', resourceRequestMemory: '256Mi', resourceLimitMemory: '256Mi'),
    containerTemplate(name: 'dotnetbuild', image: 'microsoft/aspnetcore-build:2.0', command: 'cat', ttyEnabled: true),
    containerTemplate(name: 'docker', image: 'docker:latest', command: 'cat', ttyEnabled: true),
    containerTemplate(name: 'kubectl', image: 'lachlanevenson/k8s-kubectl:v1.7.4', command: 'cat', ttyEnabled: true)
],
volumes:[
    hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock')
])
    {
        node ('jenkins-pipeline') {
            println "DEBUG: Pipeline starting"
            // grab repo from source control
            checkout scm

            // configuration parameters and variables for pipeline
            // def pwd = pwd()
            def repo = "ukphillips"
            def appMajorVersion = "1.0"
            def acrServer = "kriscontainers.azurecr.io"
            def acrJenkinsCreds = "ACR" //this is set in Jenkins global credentials
            sh 'git rev-parse HEAD > git_commit_id.txt'
            try {
                env.GIT_COMMIT_ID = readFile('git_commit_id.txt').trim()
                env.GIT_SHA = env.GIT_COMMIT_ID.substring(0, 7)
            } catch (e) {
                error "${e}"
            }
            def buildName = env.JOB_NAME
            def buildNumber = env.BUILD_NUMBER
            def imageTag = env.BRANCH_NAME + '-' + env.GIT_SHA
            def date = new Date()
            sdf = new SimpleDateFormat("MM/dd/yyyy HH:mm:ss")
            def buildDate = sdf.format(date)
            def appVersion = "${appMajorVersion}.${env.BUILD_NUMBER}"
            def apiImage = "${repo}:${imageTag}"

            // write out variables for debug purposes
            println "DEBUG: env.GIT_COMMIT_ID ==> ${env.GIT_COMMIT_ID}"
            println "DEBUG: env.GIT_SHA ==> ${env.GIT_SHA}"
            println "DEBUG: env.BRANCH_NAME ==> ${env.BRANCH_NAME}"
            println "DEBUG: env.JOB_NAME ==> ${env.JOB_NAME}"
            println "DEBUG: env.BUILD_NUMBER ==> ${env.BUILD_NUMBER}"
            println "DEBUG: appVersion ==> " + appVersion
            println "DEBUG: buildDate ==> " + buildDate
            println "DEBUG: imageTag ==> " + imageTag
            println "DEBUG: apiImage ==> " + apiImage

            println "DEBUG: code compile and test stage starting"
            stage ('BUILD: code compile and test') {
                container('dotnetbuild') {
                    sh "dotnet build"
                }
            }

            stage ('BUILD: containerize and publish TO repository') {
                println "DEBUG: build and push containers stage starting"
                container('docker') {
                    sh "docker version"
                    // Login to ACR
                    withCredentials([[$class          : 'UsernamePasswordMultiBinding', credentialsId: acrJenkinsCreds,
                                    usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) {
                        println "DEBUG: docker login ${acrServer} -u ${env.USERNAME} -p ${env.PASSWORD}"
                        sh "docker login ${acrServer} -u ${env.USERNAME} -p ${env.PASSWORD}"
                        // optionally push to Docker Hub with a custom Jenkins env variable
                    }

                    // build containers
       
                    sh "docker build -t ${apiImage}build -f Dockerfile.build ."                    
                    sh "docker create --name extract ${apiImage}build"
                    sh "docker cp extract:/app/out ./app"
                    sh "docker rm -f extract"
                    sh "docker build --no-cache -t ${apiImage} ."
                    
                    
                    // push images to repo (ACR)
                    def apiACRImage = acrServer + "/" + apiImage
                    env.ENV_API_IMAGE = "${apiACRImage}"
                    sh "docker tag ${apiImage} ${apiACRImage}"
                    sh "docker push ${apiACRImage}"
                    println "DEBUG: pushed image ${apiACRImage}"
                }
            }

            // use kubernetes plug-in to release or update app
            stage ('DEPLOY: update application on kubernetes') {
                println "DEBUG: deploy new containers to kubernetes stage"
                container('kubectl') {
                    //sh "kubectl apply -f kube-jenkins.yaml"
                    sh "kubectl set image deployment/smackapi-deploy smackapi=${env.ENV_API_IMAGE} --namespace=default"
                }
            }
        }
    }
