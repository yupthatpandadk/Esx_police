Config = {}

Config.JobName = 'police'
Config.InteractionDistance = 3.0
Config.RequireDuty = true
Config.DefaultCallsign = '2-00'

Config.Commands = {
    duty = 'pduty',
    menu = 'police',
    cuff = 'cuff',
    escort = 'escort',
    vehicle = 'putincar',
    removeVehicle = 'outcar'
}

Config.Fines = {
    { label = 'Mindre færdselsforseelse', amount = 750 },
    { label = 'Farlig kørsel', amount = 2500 },
    { label = 'Flugt fra politiet', amount = 5000 }
}
