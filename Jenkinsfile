pipeline {
    agent any
     
     environment {
         APP_NAME = "mule-helloworld"
         APP_VERSION = "1.0.3-SNAPSHOT"

         REGISTRY = "registry.in.luxair.lu"
         REGISTRY_NAMESPACE = "snsakala"
         REGISTRY_CREDS_ID = "registry_toot"

         APP_ID = "${APP_NAME}-${APP_VERSION}"
         IMAGE_ID =  "${REGISTRY_NAMESPACE}/${APP_NAME}:${APP_VERSION}"
         REGISTRY_URL = "https://${REGISTRY}"
     }

    stages {

        stage('Unit Test') {
            agent { docker { image "maven:3.6.3" } }

            steps {
                sh "mvn test"
            }
        }

        stage('Build Source') {
            agent { docker { image "maven:3.6.3" } }

            steps {
                sh "mvn package"
                stash name: 'jar', includes: "target/${APP_ID}-mule-application.jar"
            }
        }

        stage('Build Docker Image') {
            steps {
                unstash name: 'jar'
                sh "docker build -t ${REGISTRY}/${IMAGE_ID} ."
            }
        }

        stage('Push Docker Image') {
            steps {
                withDockerRegistry([credentialsId: "${REGISTRY_CREDS_ID}", url: "${REGISTRY_URL}"]) {
                    sh "docker push ${REGISTRY}/${IMAGE_ID}"
                }
            }
        }

        stage('Make Deployment Configuration') {
            steps {
                sh "rm -fr ${APP_NAME} && mkdir ${APP_NAME}"
                sh "cat docker-compose.tmpl.yaml > ${APP_NAME}/docker-compose.yaml"
                sh "tar cf ${APP_ID}.tar ${APP_NAME}"
                stash name: 'tar', includes: "${APP_ID}.tar"
            }
        }
        stage('Deploy Application') {
            steps {
                unstash name: 'tar'
                scp_file("${APP_ID}.tar", "deployments")
                ssh_cmd "'rm -fr ${APP_NAME} && find deployments && tar xf deployments/${APP_ID}.tar'"
                ssh_cmd "'cd ${APP_NAME} && docker-compose up -d'"
            }
        }
        stage('Test Application') {
            steps {
                sh "sleep 20" 
                sh "curl -s -o /dev/null -w '%{http_code}' http://toot.svr.luxair/${APP_NAME}/health | grep -w 200"
            }
        }
    }
}

def ssh_cmd(cmd) {
    sshagent(['deploy_toot']) {
        sh "ssh -o StrictHostKeyChecking=no snsakala@toot.svr.luxair $cmd"
    }
}

def scp_file(file, target) {
    sshagent(['deploy_toot']) {
        sh "scp -o StrictHostKeyChecking=no $file snsakala@toot.svr.luxair:$target"
    }
}
