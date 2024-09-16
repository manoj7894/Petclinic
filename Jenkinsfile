pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = "manoj3003/petclinic:${BUILD_NUMBER}"
        OLD_IMAGE_TAG_PATTERN = "manoj3003/petclinic:*"  // Pattern to match old images
        GIT_REPO_NAME = "Petclinic"
        GIT_USER_NAME = "manoj7894"
        DEPLOYMENT_FILE_PATH = "Manifests/dss.yml"  // Adjust the path if necessary
        SCANNER_HOME = tool 'sonar-scanner'
        WORKSPACE_BASE = "/var/lib/jenkins/workspace" // Set this to the base path of your Jenkins workspaces
    }

    stages {
        /*
         stage('Cleanup Old Workspaces') {
            steps {
                script {
                    echo "Cleaning up all workspaces except the current build..."

                    // Get the current workspace directory
                    def currentWorkspaceDir = env.WORKSPACE

                    // Use a shell script to clean up old workspaces
                    sh '''
                        #!/bin/bash

                        # Enable diagnostics
                        set -x
                        echo "Current workspace: ${currentWorkspaceDir}"

                        # The directory we need to preserve
                        PRESERVE_DIR="${currentWorkspaceDir}"

                        # Base path for Jenkins workspaces
                        BASE_PATH="${WORKSPACE_BASE}"

                        # Ensure that the current build workspace directory exists
                        if [ ! -d "$PRESERVE_DIR" ]; then
                            echo "Current workspace directory $PRESERVE_DIR does not exist. Skipping cleanup."
                            exit 0
                        fi

                        # Find and delete directories excluding the current build directory
                        for dir in $(find $BASE_PATH -maxdepth 1 -type d ! -path "$PRESERVE_DIR" ! -path "$BASE_PATH"); do
                            echo "Deleting old workspace: $dir"
                            rm -rf "$dir"
                        done
                    '''
                }
            }
        } */

        stage('Check Old Docker Images') {
            steps {
                script {
                    echo "Checking for old Docker images..."
                    
                    def oldImages = sh(script: "docker images --format '{{.Repository}}:{{.Tag}}' | grep '^manoj3003/petclinic:' || true", returnStdout: true).trim()
                    echo "Old images found: ${oldImages}"
                    
                    if (oldImages) {
                        env.OLD_IMAGES_EXIST = 'true'
                    } else {
                        echo "No old images found."
                        env.OLD_IMAGES_EXIST = 'false'
                    }
                }
            }
        }

        stage('Cleanup Old Docker Images') {
            when {
                expression { env.OLD_IMAGES_EXIST == 'true' }
            }
            steps {
                script {
                    echo "Cleaning up old Docker images..."
                    
                    def oldImages = sh(script: "docker images --format '{{.Repository}}:{{.Tag}}' | grep '^manoj3003/petclinic:' || true", returnStdout: true).trim()
                    echo "Old images found for cleanup: ${oldImages}"
                    
                    if (oldImages) {
                        def imagesToRemove = oldImages.split('\n').findAll { image ->
                            image != DOCKER_IMAGE
                        }
                        
                        if (imagesToRemove) {
                            imagesToRemove.each { image ->
                                echo "Attempting to remove old image ${image}"
                                try {
                                    sh """
                                        if docker images -q ${image} > /dev/null 2>&1; then
                                            docker rmi -f ${image} || echo 'Failed to remove image ${image} - might be in use or other error.'
                                        else
                                            echo 'Image ${image} does not exist.'
                                        fi
                                    """
                                } catch (Exception e) {
                                    echo "Error while attempting to remove image ${image}: ${e.getMessage()}"
                                }
                            }
                        } else {
                            echo "No old images to remove."
                        }
                    } else {
                        echo "No old images found matching pattern 'manoj3003/database:'"
                    }
                }
            }
        }
        
        stage('Cleanup Old Trivy Reports') {
            steps {
                script {
                    echo "Cleaning up old Trivy reports..."
                    sh '''
                        rm -f trivy.txt
                        rm -f fs-report.html
                    '''
                }
            }
        }
        
        stage('Get Code') {
            steps {
                git branch: 'main', url: 'https://github.com/manoj7894/Petclinic.git'
            }
        }
        
        stage('OWASP Scan') {
            when {
                expression {
                    fileExists('pom.xml')
                }
            }
            steps {
                dependencyCheck additionalArguments: '', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        
        // stage("OWASP Dependency Check"){
        //     steps{
        //         dependencyCheck additionalArguments: '--scan ./ --format HTML ', odcInstallation: 'DP-Check'
        //         dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
        //     }
        // }
        
        stage('Trivy Filesystem Scan') {
            steps {
                script {
                    sh "trivy fs --format table -o fs-report.html ."
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'Docker_id', toolName: 'Docker') {
                        sh "docker build -t ${DOCKER_IMAGE} ."
                    }
                }
            }
        }
        
        stage('Trivy Image Scan') {
            steps {
                script {
                    sh "trivy image ${DOCKER_IMAGE} > trivy.txt"
                }
            }
        }
        
        // stage('SonarQube') {
        //     steps {
        //         withSonarQubeEnv('Sonar_Install') {
        //             sh '''$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Campground \
        //             -Dsonar.projectKey=Campground \
        //             -Dsonar.host.url=http://13.232.72.13:9000'''
        //         }
        //     }
        // }
        
        stage('SonarQube') {
            steps {
                withSonarQubeEnv('Sonar_Install') {
                    sh '''$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Petclinic \
                    -Dsonar.java.binaries=. \
                    -Dsonar.projectKey=Petclinic \
                    -Dsonar.host.url=http://13.233.77.222:9000'''
                }
            }
        }

        
        stage('Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'Docker_id', toolName: 'Docker') {
                        sh "docker push ${DOCKER_IMAGE}"
                    }
                }
            }
        }
        
        stage('Update Deployment File') {
            steps {
                withCredentials([string(credentialsId: 'github_id', variable: 'GITHUB_TOKEN')]) {
                    script {
                        sh '''
                            git config user.email "manojvarmapotthuri3003@gmail.com"
                            git config user.name "Manojvarma Potthuri"
                        '''
                        
                        sh 'git checkout main'
                        sh 'cat ${DEPLOYMENT_FILE_PATH}'
                        
                        sh '''
                            sed -i "s|image: manoj3003/petclinic:[^[:space:]]*|image: manoj3003/petclinic:${BUILD_NUMBER}|g" ${DEPLOYMENT_FILE_PATH}
                        '''
                        
                        sh '''
                            if git diff --quiet; then
                                echo "No changes detected in ${DEPLOYMENT_FILE_PATH}"
                            else
                                git add ${DEPLOYMENT_FILE_PATH}
                                git commit -m "Update deployment image to version ${BUILD_NUMBER}"
                                git push -f https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME}.git HEAD:main
                            fi
                        '''
                    }
                }
            }
        }
    }
    
    post {
        always {
            emailext attachLog: true,
                subject: "Pipeline Status: ${BUILD_NUMBER}",
                body: '''<html>
                           <body>
                              <p>Build Status: ${BUILD_STATUS}</p>
                              <p>Build Number: ${BUILD_NUMBER}</p>
                              <p>Check the <a href="${BUILD_URL}">console output</a>.</p>
                           </body>
                        </html>''',
                to: 'manojvarmapotthutri@gmail.com',
                from: 'jenkins@example.com',
                replyTo: 'jenkins@example.com',
                attachmentsPattern: 'trivy.txt',
                mimeType: 'text/html'
        }
    }
}
