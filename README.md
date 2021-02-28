# Chronicle

Chronicle is a multi-purpose chat bot.

It currently supports Matrix, but has ambitions of supporting Discord in the
future.

Chronicle is still heavily work-in-progress, and the hobby of an occasionally
productive fellow.

## Features

- List available commands (`!listcommands`) and get help with them (`!help
    [COMMAND]`)
- Ping (returns `Pong!`; good for testing connectivity)
- Dice Roller (`!roll 2d4` --> `Roll: 2d4 ([2, 1]) ==> 3`)
- 8-ball (`!8ball Will I win the lottery?` --> `Try again later`)
- Ad-hoc simple custom commands (`!addcommand hello Hey there!` --> `!hello` -->
  `Hey there!`)
- Run in a Docker container!
- More to come!

## Planned Features

- [ ] Simple calculator (`!calc 8 + (9-10)` --> `Calc: 8 + (9 - 10) ==> 7`)
- [ ] Simple games (Blackjack, High/Low)
- [ ] A "mystery" game (Kind of like _Clue!_ or _Noir Syndrome_)
- [ ] A "progress quest" like game (time-based character auto-progression)
- [ ] Expanded custom commands (allow for commands with arguments)
- [ ] Enabling of add-on features (ie., everything mentioned above) per room
- [ ] Establish/restrict command permissions per user/role per room.
- [ ] Change the command prefix (from default `!` to whatever you'd like!)

# Development

You can run your own instance of Chronicle with a few steps:

1. Fork the repository, and clone it locally
2. Setup a bot user in Matrix, and get its "Access Token"
3. Update `config/bot.yml` with the Homeserver URL, and the Access Token
4. Update `config/db.yml` with any desired changes (defaults use SQLite)
5. (Optional) Update `config/bot.yml` with any additional changes
6. Run `bundle update` to install dependencies
7. Run `rake chronicle:start`
8. Invite the bot user to a room, and `!ping` to make sure it's working!

# Docker

The included Dockerfile is very simplistic, and may be expanded in the future.
For now, there is no pre-built image stored in a Hub, so you'll need to build
your own.

1. Fork the repository, and clone it locally
2. Setup a bot user in Matrix, and get its "Access Token"
3. Update `config/bot.yml` with the Homeserver URL, and the Access Token
4. Update `config/db.yml` with any desired changes (defaults use SQLite)
5. (Optional) Update `config/bot.yml` with any additional changes
6. Build the image: `docker build -t chronicle-bot .`
7. Run Chronicle in Docker with `docker run --rm --name chronicle chronicle-bot`
8. Invite the bot user to a room, and `!ping` to make sure it's working!

# Contribute

If you are interested in contributing to Chronicle, first let me say thanks!
Next, please follow these steps:

1. Fork the repository, and perform any changes you'd like.
2. Submit a pull request, explaining the changes.
3. Work with me to get those changes merged.

Chronicle is a hobby project, and as such I may not be immediately responsive to
any requests. Please do not be discouraged! I will try to address any issues or
pull requests in a reasonable time.

# Issues

If you find something amiss with Chronicle, please submit an issue! I will try
to address it in a reasonable time.

# Contact

If you're interested in discussing Chronicle, you can speak with me on Matrix!
I'm [Vagabond](https://matrix.to/#/@vagabondazulien:exp.farm).
