// Template for a Jenkinsfile that builds a Docker image from a Dockerfile in a source repo. To be used with a Multibranch Pipeline job
 
// Jenkins Shared Libraries are implemented in our CI model (https://connect.us.cray.com/confluence/display/DST/Best+Practices+and+How-To%27s)
// Jenkins Global Variables are enabled in our CI model (TODO: **INSERT LINK**)
 
////////////////////////////////////////// JENKINS SHARED LIBRARY //////////////////////////////////////////
 
// Library repo: https://stash.us.cray.com/projects/DST/repos/jenkins-shared-library
 
// Transfers the build artifact(s) to iyumcf's DST yum repository
// If the branch is master: /var/www/html/dstrepo/dev
// If the branch isn't master: /var/www/html/dstrepo/predev
def transfer = new com.cray.Transfer()
 
// Sends notifications to a specific HipChat room defined via Jenkins global variables
// Includes build result, cause, build url, job name, build number, and duration
def notify = new com.cray.Notify()
 
// This sends out an email to a user or users in a git project after the build is over
// Similar to the 'notify' function it contains the job name and build url
// It also includes git commit diff, revision changes, and more
def mail = new com.cray.Mail()
 
//////////////////////////////////////// END JENKINS SHARED LIBRARY ////////////////////////////////////////
 
// Begin defining the pipeline using agents, stages, and steps
pipeline {
    // Define agent
    agent any
 
    // Environment variables required for the build. 
    environment {
		TARGET_ARCH=${ARCH}
        TARGET_REPO="centos"
        TARGET_REPO_VERSION="7"
        IMAGE_PREFIX = "${TARGET_REPO}-${TARGET_REPO_VERSION}"
        APP = 'dst_os_rsync'
        VERSION = sh(returnStdout: true, script: "cat .version").trim()
        GIT_TAG = sh(returnStdout: true, script: "git log -n 1 --pretty=format:'%h'").trim()
        IMAGE_TAG = "v${VERSION}-${BUILD_NUMBER}-${GIT_TAG}"
        IMAGE = "${CRAY_DOCKER_REGISTRY}/${IMAGE_PREFIX}/${APP}:${IMAGE_TAG}"
    }
 
    stages {
        stage('BUILD: Prep') {
            steps {
                // Print environment variables
                echo """
                BRANCH_NAME=${env.BRANCH_NAME}
                BUILD_ID=${env.BUILD_ID}
                BUILD_NUMBER=${env.BUILD_NUMBER}
                BUILD_TAG=${env.BUILD_TAG}
                BUILD_URL=${env.BUILD_URL}
                HOME=${env.HOME}
                JENKINS_URL=${env.JENKINS_URL}
                JOB_BASE_NAME=${env.JOB_BASE_NAME}
                JOB_NAME=${env.JOB_NAME}
                JOB_URL=${env.JOB_URL}
                WORKSPACE=${env.WORKSPACE}
                """
 
                // Remove existing 'build' directory
                sh "rm -rf build"
 
                // Create the 'build' directory to perform the build in and store build artifacts
                sh "mkdir -p build"
            }
        }
 
        // Pipeline stage 'BUILD', action 'Checkout': Checkout code from source code management (Git, Bitbucket, etc)
        stage('BUILD: Checkout') {
            steps {
                checkout scm
 
                // Update linked submodules
                sh "git submodule update --init --recursive ./build_common"
            }
        }
 
        stage('BUILD') {
            // Run all the steps for this stage in the specified Docker container.
            agent {
                docker {
                    image "${env.CRAY_DOCKER_REGISTRY}/cray/build_environment:v1.1" // Name of the image to use for the container
                    registryUrl "http://${env.CRAY_DOCKER_REGISTRY}" // Path to Docker registry
                }
            }
 
            // Compilation steps and scripts for both the application(s) and its unit test(s) 
            // run here (configure, make, docker build, etc)
            steps {
                // IMPORTANT: Unit tests for the built image must be executed 
                // from within the Dockerfile, however it can be defined 
                // externally via a Bash script for example
                dir('build') {
                    // Docker 'build' command with the '-t' option to name/tag 
                    // the image, and the path to the Dockerfile and its dependencies to build from
                    // The Dockerfile path points up one directory since we entered the 'build' 
                    // directory using the 'dir' command above
                    sh "docker build -t ${IMAGE} ../"
                }
            }
        }
 
        // Pipeline stage 'UNIT TEST': Execute appropriate unit test(s) for the application(s)
        // stage('UNIT TEST') {
        //     // Run unit tests and continue only if they all pass. If at least one fails 
        //     // then exit the Jenkins job with an error message
        //     steps {
        //         // Steps for unit testing
        //     }
        // }
 
        // Pipeline stage 'PUBLISH', action 'Package': Generate a package (RPM, iso, tar, etc)
        // If generating an RPM, for example, then the 'rpmbuild' command would run here
        stage('PUBLISH: Package') {
            steps {
                // Docker 'save' command with a path to the destination of the '.tar.gz' file, 
                // and the path to the source image
                // This creates an archive of the image in the form of '.tar.gz' in order to 
                // have an offline version as well (not just in the registry)
                // Not to be confused with the built in 'archiveArtifacts' command for Jenkins. 
                // This is specific and unique to Docker
                sh "docker save -o build/${APP}.tar.gz ${IMAGE}"               
            }
        }
 
        // Pipeline stage 'PUBLISH', action 'Docker Push': unique to docker images 
        // (pushes image to docker registry)
        // The current DST Docker Registry is running on iyumcf
        stage('PUBLISH: Docker Push') {
            steps {
                // There's no need to run 'docker tag' here since the image is pre-configured 
                // to be tagged using variables in the 'environment' block
                // The 'IMAGE' variable contains the necessary information such as registry 
                // url, port, path, image name, and image tag.
                sh "docker push ${IMAGE}"
            }
        }
 
        // Pipeline stage 'PUBLISH', action 'Transfer': Transfer the artifact(s) to the DST 
        // yum repo on iyumcf server
        stage('PUBLISH: Transfer') {
            steps {
                script {
                    // Transfer the artifact(s) using the DST-provided 'transfer' function. 
                    // Include the path to the artifact(s) to be transferred
                    // transfer.artifact("build/*.tar.gz")
                }
            }
        }
    }
 
    // Steps to run if all of the 'stages' complete successfully (success), 
    // at least one stage fails (failure), or regardless of the outcome (always)
    // The execution order for condition blocks are found in the Jenkins Pipeline 
    // Syntax documentation, in the 'post' section
    post('Post Run Conditions') {
        // always {
        //     // Clean up the local build registry whether the build was successful or not. Doesn't work with the current DST setup:
        //     // DST registry is running on iyumcf. Jenkins is running in a Docker container in iyumcf, which launches the 'build_environment:v1.2' container,
        //     //   and both the Jenkins and 'build_environment:v1.2' containers are mounting the '/var/run/docker.sock' socket on iyumcf. Meaninng deleting
        //     //   the image inside 'build_environment:v1.2' would also delete it from the DST registry :(
 
        //     sh(returnStdout: true, script: "docker rmi ${IMAGE}")
        // }
 
        success {
            // Archive the artifact(s) using the Jenkins built-in command
            // This is for Jenkins use only and will show up under "Last Successful Artifacts" in the Job's build status page
            // Any output file or files can be archived for Jenkins using the 'archiveArtifacts' command (RPM, ISO, .txt, .tar, .zip, etc)
            archiveArtifacts artifacts: 'build/*.tar.gz', fingerprint: true
 
            // Delete the 'build' directory we created at the very beginning
            // The 'dir' command is similar to 'cd' in Bash, it's used to change into the 'build' directory here
            dir('build') {
                // the 'deleteDir' command recursively deletes the current directory
                deleteDir()
            }         
        }
 
        failure {
            // Send out email notifications using the DST-provided 'mail' function. 
            // Include the build status followed by a message string
            script {
                mail.build_status('fail', "Failed: ${env.JOB_NAME}")
            }
 
            // Send out HipChat notifications using the DST-provided 'notify' function. 
            // Include the job status, HipChat room, and build result
            script {
                notify.hipchat('Finished', '${env.DST_HIPCHAT_ROOM}', currentBuild.result, true)
            }
 
            // Delete the 'build' directory we created at the very beginning
            // The 'dir' command is similar to 'cd' in Bash, it's used to change into the 'build' directory here
            dir('build') {
                // the 'deleteDir' command recursively deletes the current directory
                deleteDir()
            }
        }
    }
}
