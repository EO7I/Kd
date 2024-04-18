pipeline {
  agent any

  // 해당 스크립트 내에서 사용할 로컬 변수들 설정-
  // 레포지토리가 없으면 생성됨
  // Credential들에는 젠킨스 크레덴셜에서 설정한 ID를 사용 
  environment {
    //dockerHubRegistry = 'ccamm1/demo-eks-cicd' 
    //dockerHubRegistryCredential = 'credential-dockerhub'
    awsecrRegistry = '730335456215.dkr.ecr.ap-northeast-2.amazonaws.com/eks-demo-repo'
    awsecrRegistryCredentail = 'credential-AWS-ECR'
    githubCredential = 'credential-github'
    gitEmail = '2071ly@gmail.com'
    gitName = 'EO7I'
  }

  stages {

    // 깃허브 계정으로 레포지토리를 클론한다.
    stage('Checkout Application Git Branch') {
      steps {
        checkout([$class: 'GitSCM', branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[credentialsId: githubCredential, url: 'https://github.com/EO7I/Kd.git']]])
      }
      // steps 가 끝날 경우 실행한다.
      // steps 가 실패할 경우에는 failure 를 실행하고 성공할 경우에는 success 를 실행한다.
      post {
        failure {
          echo 'Repository clone failure' 
        }
        success {
          echo 'Repository clone success' 
        }
      }
    }

    stage('Docker Image Build') {
      steps {
        // 도커 이미지 빌드
        sh "docker build . -t ${awsecrRegistry}:${currentBuild.number}"
        sh "docker build . -t ${awsecrRegistry}:latest"
      }
      // 성공, 실패 시 슬랙에 알람오도록 설정
      post {
        failure {
          echo 'Docker image build failure'
          //slackSend (color: '#FF0000', message: "FAILED: Docker Image Build '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        }
        success {
          echo 'Docker image build success'
          //slackSend (color: '#0AC9FF', message: "SUCCESS: Docker Image Build '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        }
      }
    }  

    stage('Docker Image Push') {
      steps {
        // 젠킨스에 등록한 계정으로 ECR 에 이미지 푸시
        withDockerRegistry([url: "https://${awsecrRegistry}", credentialsId: "ecr:ap-northeast-2:${awsecrRegistryCredentail}"]) {
          sh "docker push ${awsecrRegistry}:${currentBuild.number}"
          sh "docker push ${awsecrRegistry}:latest"
          // 10초 쉰 후에 다음 작업 이어나가도록 함
          sleep 10
        } 
      }
      post {
        failure {
          echo 'Docker Image Push failure'
          sh "docker rmi ${awsecrRegistry}:${currentBuild.number}"
          sh "docker rmi ${awsecrRegistry}:latest"
          //slackSend (color: '#FF0000', message: "FAILED: Docker Image Push '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        }
        success {
          echo 'Docker Image Push success'
          sh "docker rmi ${awsecrRegistry}:${currentBuild.number}"
          sh "docker rmi ${awsecrRegistry}:latest"
          //slackSend (color: '#0AC9FF', message: "SUCCESS: Docker Image Push '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        }
      }
    }

    // updated docker image 태그를 git push 
    stage('Deploy') { 
      steps {
        // git 계정 로그인, 해당 레포지토리의 main 브랜치에서 클론
        git credentialsId: githubCredential,
            url: 'https://github.com/EO7I/Kd.git',
            branch: 'main'  
        
        // 이미지 태그 변경 후 메인 브랜치에 푸시
        sh "git config --global user.email ${gitEmail}"
        sh "git config --global user.name ${gitName}"
        sh "cd prod && kustomize edit set image ${awsecrRegistry}:${currentBuild.number}"
        sh "git add -A"
        sh "git status"
        sh "git commit -m 'update the image tag'"
        sh "git branch -M main"
      }
    }
         stage('Push to Git Repository') {
      steps {
        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: githubCredential, usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD']]) {
          sh "git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/EO7I/Kd.git"
        }
      }
    }
  }
}
