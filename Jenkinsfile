pipeline {
    agent any
     
    environment {
        REGISTRY = "registry.in.luxair.lu"
        REGISTRY_NAMESPACE = "snsakala"
        REGISTRY_CREDS_ID = "registry_toot"

        DEPLOY_HOST = "toot.svr.luxair"
        DEPLOY_USER = "snsakala"
        DEPLOY_CREDS_ID = "deploy_toot"

        APP_NAME = readMavenPom().getArtifactId()
        APP_VERSION = readMavenPom().getVersion()

        APP_ID = "${APP_NAME}-${APP_VERSION}"
        IMAGE =  "${REGISTRY}/${REGISTRY_NAMESPACE}/${APP_NAME}:${APP_VERSION}"
        REGISTRY_URL = "https://${REGISTRY}"
        SERVICE_HEALTH_URL = "http://${DEPLOY_HOST}/${APP_NAME}/health"
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
                sh "docker build --build-arg APP_ID=${APP_ID} -t ${IMAGE} ."
            }
        }

        stage('Push Docker Image') {
            steps {
                withDockerRegistry([credentialsId: "${REGISTRY_CREDS_ID}", url: "${REGISTRY_URL}"]) {
                    sh "docker push ${IMAGE}"
                }
            }
        }

        stage('Make Deployment Configuration') {
            agent { docker { image "${REGISTRY}/dockerize:0.6.1" } }

            steps {
                sh "rm -fr ${APP_NAME} && mkdir ${APP_NAME}"
                sh "dockerize -template docker-compose.tmpl.yaml:${APP_NAME}/docker-compose.yaml"
                sh "cat ${APP_NAME}/docker-compose.yaml"
                sh "tar cf ${APP_ID}.tar ${APP_NAME}"
                stash name: 'tar', includes: "${APP_ID}.tar"
            }
        }
        stage('Deploy Application') {
            steps {
                unstash name: 'tar'
                scp_file("${APP_ID}.tar", "deployments")
                ssh_cmd "'rm -fr ${APP_NAME} && tar xf deployments/${APP_ID}.tar'"
                ssh_cmd "'cd ${APP_NAME} && docker-compose up -d'"
            }
        }
        stage('Test Application') {
            steps {
                sh "sleep 20" 
                sh "curl -s -o /dev/null -w '%{http_code}' ${SERVICE_HEALTH_URL} | grep -w 200"
            }
        }
    }
}

def ssh_cmd(cmd) {
    sshagent(["${DEPLOY_CREDS_ID}"]) {
        sh "ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} $cmd"
    }
}

def scp_file(file, target) {
    sshagent(["${DEPLOY_CREDS_ID}"]) {
        sh "scp -o StrictHostKeyChecking=no $file ${DEPLOY_USER}@${DEPLOY_HOST}:$target"
    }
}
