# Description
#   Interact with AWS Device Farm
#
# Configuration:
#   AWS_ACCESS_KEY_ID -
#   AWS_SECRET_ACCESS_KEY -
#
# Commands:
#   hubot devicefarm list projects [limit] - List available projects
#   hubot devicefarm list runs <project-name> [limit] - List runs under specified project
#
# Author:
#   Andrew Hawker <andrew.r.hawker@gmail.com>

aws = require('aws-sdk');


accessKey = process.env.AWS_ACCESS_KEY_ID;
secretKey = process.env.AWS_SECRET_ACCESS_KEY;


devicefarm = new aws.DeviceFarm({
    accessKeyId: accessKey,
    secretAccessKey: secretKey,
    region: 'us-west-2'
});


urlRoot = "https://console.aws.amazon.com/devicefarm/home?#"


parseArn = (arn) ->
  sections = ['arn', 'partition', 'service', 'region', 'account', 'resource_type', 'resource']
  return arn.split(':').reduce((result, part, index) ->
    result[sections[index]] = part
    return result
  , {})


projectIdFromArn = (arn) ->
  parts = parseArn(arn)
  return parts.resource


runIdFromArn = (arn) ->
  parts = parseArn(arn)
  [projectId, runId] = parts.resource.split('/')
  return runId


projectUrl = (project) ->
  id = projectIdFromArn(project.arn)
  return urlRoot + "/projects/#{id}"


runUrl = (project, run) ->
  id = runIdFromArn(run.arn)
  return projectUrl(project) + "/runs/#{id}"


prettyProject = (project) ->
  return "#{project.name} at #{projectUrl(project)}"


prettyRun = (project, run) ->
  return "[#{run.status}|#{run.result}] - #{run.name} with #{run.type} tests on #{run.totalJobs} devices " +
         "(Passed: #{run.counters.passed}, Failed: #{run.counters.failed}, " +
         "Warned: #{run.counters.warned}, Errored: #{run.counters.errored}, " +
         "Skipped: #{run.counters.skipped}, Stopped: #{run.counters.stopped}) at #{runUrl(project, run)}"


listProjects = (callback, limit = -1) ->
  devicefarm.listProjects((err, data) ->
      callback(err, data.projects[..limit])
  )


listRuns = (projectName, callback, limit = -1) ->
  listProjects((err, projects) ->
    arn = (project.arn for project in projects when project.name == projectName)[0]
    devicefarm.listRuns({arn: arn}, (err, data) ->
      callback(err, project, data.runs[..limit])
    )
  )


module.exports = (robot) ->

  # `hubot devicefarm list projects [limit]`
  # Print [limit] number of projects in your AWS Device Farm account.
  robot.respond /devicefarm list projects\s*(\d*)/, (res) ->
    limit = res.match[1] || 10
    res.send 'Querying projects...'
    listProjects(((err, projects) ->
      res.send (prettyProject(project) for project, i in projects).join("\n")
    ), limit);

  # `hubot devicefarm list runs <project-name> [limit]`
  # Print [limit] number of runs from <project-name> in descending order from when they were scheduled.
  robot.respond /devicefarm list runs ([a-zA-Z0-9_\-]+)\s*(\d*)/, (res) ->
    projectName = res.match[1]
    limit = res.match[2] || 10
    res.send 'Querying runs...'
    listRuns(projectName, ((err, project, runs) ->
      res.send (prettyRun(project, run) for run, i in runs).join("\n")
    ), limit)
