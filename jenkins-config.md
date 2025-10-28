# Jenkins Configuration Guide for testproject

## Prerequisites

### 1. Jenkins Plugins Required
Install the following plugins in Jenkins:
- Pipeline
- Docker Pipeline
- Maven Integration
- Git
- Credentials Binding
- Slack Notification (optional)
- Email Extension (optional)
- SonarQube Scanner (optional)
- Checkstyle (optional)

### 2. Global Tools Configuration
Configure the following tools in Jenkins Global Tool Configuration:

#### Maven
- Name: `Maven-3.8.6`
- Version: `3.8.6`
- Install automatically: ✅

#### JDK
- Name: `JDK-17`
- Version: `17`
- Install automatically: ✅

### 3. Credentials Setup
Add the following credentials in Jenkins Credential Manager:

#### Database Credentials
- ID: `db-url`
- Type: Secret text
- Value: `jdbc:postgresql://168.220.248.40:5432/team_1_db?timezone=UTC&useSSL=false&serverTimezone=UTC`

- ID: `db-username`
- Type: Secret text
- Value: `team_1`

- ID: `db-password`
- Type: Secret text
- Value: `team_1`

#### Docker Registry Credentials (if using private registry)
- ID: `docker-registry-credentials`
- Type: Username with password
- Username: `your-docker-username`
- Password: `your-docker-password`

## Pipeline Configuration

### 1. Create New Pipeline Job
1. Go to Jenkins Dashboard
2. Click "New Item"
3. Enter name: `testproject-pipeline`
4. Select "Pipeline"
5. Click "OK"

### 2. Configure Pipeline
1. In the pipeline configuration:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: `https://github.com/vking6007/testproject.git`
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`

### 3. Build Triggers
Configure build triggers as needed:
- GitHub hook trigger for GITScm polling
- Poll SCM: `H/5 * * * *` (every 5 minutes)
- Build periodically: `H 2 * * *` (daily at 2 AM)

## Environment Variables

### Global Environment Variables
Add these in Jenkins Global Properties:
- `DOCKER_REGISTRY`: `your-docker-registry.com`
- `SONAR_TOKEN`: `your-sonarqube-token` (if using SonarQube)

### Pipeline-Specific Variables
The Jenkinsfile uses these environment variables:
- `APP_NAME`: `testproject`
- `APP_VERSION`: `0.0.1-SNAPSHOT`
- `MAVEN_OPTS`: `-Xmx1024m -XX:MaxPermSize=256m`

## Deployment Environments

### Staging Environment
- Port: `8086`
- Profile: `staging`
- Container: `testproject-staging`

### Production Environment
- Port: `8085`
- Profile: `prod`
- Container: `testproject-prod`

## Monitoring and Notifications

### Health Checks
The pipeline includes health checks for:
- Application startup
- Database connectivity
- API endpoints

### Notifications
Configure notifications for:
- Slack channel: `#deployments`
- Email notifications
- Build status updates

## Security Considerations

### Database Credentials
- Store database credentials securely in Jenkins Credential Manager
- Use environment variables in pipeline
- Never hardcode credentials in code

### Docker Security
- Use non-root user in Dockerfile
- Scan images for vulnerabilities
- Use specific image tags, not `latest`

### Network Security
- Use Docker networks for container communication
- Configure firewall rules
- Use HTTPS for external access

## Troubleshooting

### Common Issues

#### Build Failures
1. Check Maven and JDK installation
2. Verify Git repository access
3. Check database connectivity
4. Review build logs

#### Docker Issues
1. Ensure Docker daemon is running
2. Check Docker registry credentials
3. Verify image build process
4. Check container logs

#### Deployment Issues
1. Verify environment variables
2. Check port availability
3. Review application logs
4. Test health endpoints

### Log Locations
- Jenkins logs: `/var/log/jenkins/`
- Application logs: Docker container logs
- Build logs: Jenkins console output

## Best Practices

### Code Quality
- Run unit tests in every build
- Use code quality tools (SonarQube, Checkstyle)
- Implement security scanning
- Review pull requests

### Deployment
- Use blue-green deployments
- Implement rollback procedures
- Monitor application health
- Use infrastructure as code

### Security
- Regular security updates
- Scan dependencies for vulnerabilities
- Use least privilege principle
- Encrypt sensitive data

## Support

For issues or questions:
1. Check Jenkins console output
2. Review application logs
3. Check database connectivity
4. Verify environment configuration

