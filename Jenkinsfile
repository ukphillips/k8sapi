node {
    stage 'Checkout'
        checkout scm

    stage 'Build'
        bat 'rake build'

    stage 'Test'
        bat 'rake test'
}
