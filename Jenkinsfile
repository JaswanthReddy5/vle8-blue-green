pipeline {
    agent any

    environment {
        IMAGE = "myapp"
        MINIKUBE_HOME = "/home/ubuntu"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Green Image') {
            steps {
                sh 'docker build --build-arg VERSION=v2 -t ${IMAGE}:v2 app/'
            }
        }

        stage('Load Image into Minikube') {
            steps {
                sh 'minikube image load ${IMAGE}:v2'
            }
        }

        stage('Deploy Green') {
            steps {
                sh 'kubectl apply -f k8s/deployment-green.yaml'
                sh 'kubectl rollout status deployment/myapp-green --timeout=120s'
            }
        }

        stage('Test Green') {
            steps {
                sh '''
                    GREEN_POD=$(kubectl get pod -l app=myapp,color=green -o jsonpath="{.items[0].metadata.name}")
                    kubectl exec "$GREEN_POD" -- curl -sf http://localhost | grep "GREEN (v2)"
                '''
            }
        }

        stage('Approve Traffic Switch') {
            steps {
                input message: 'Green is deployed and tested. Switch production traffic to Green?', ok: 'Switch to Green'
            }
        }

        stage('Switch Traffic to Green') {
            steps {
                sh '''
                    kubectl patch service myapp-service \
                      -p '{"spec":{"selector":{"app":"myapp","color":"green"}}}'
                '''
            }
        }

        stage('Verify') {
            steps {
                sh '''
                    sleep 3
                    MINIKUBE_IP=$(minikube ip)
                    curl -sf http://${MINIKUBE_IP}:30080 | grep "GREEN (v2)"
                '''
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed - traffic was NOT switched (or switch itself failed). Service selector unchanged unless the Switch stage ran.'
        }
    }
}
