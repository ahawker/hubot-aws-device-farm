# hubot-aws-device-farm

Interact with AWS Device Farm

See [`src/aws-device-farm.coffee`](src/aws-device-farm.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-aws-device-farm --save`

Then add **hubot-aws-device-farm** to your `external-scripts.json`:

```json
[
  "hubot-aws-device-farm"
]
```

## Sample Interaction

```
user1>> hubot devicefarm list projects
hubot>> ...

user1>> hubot devicefarm list runs my-project
hubot>> ...
```
