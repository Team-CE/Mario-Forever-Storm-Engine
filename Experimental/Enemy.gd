extends AliveBody

export var shell_speed: float = 250
export(HIT_TYPE) var stomp: bool = HIT_TYPE.STOMP

#Персонально для михи
#1.Мы создаем врага с типом Enemy @reflexguru
#2.Суда идут только переменные для врагов
#3.TODO Powerups с наследуемым типом AliveBody  @SuperDooJMan, @reflexguru НО SuperMany в первую очередь (Все я щяс отрублюсь прям на клаве я спать)
#4.Вызывать СУПЕР методы (._ready() - пример) в не пустых родительских функциях, а иначит тот код который в родительском класск робить не буд
#5.лупер-залупер


func _ready():
  ._ready() #Execute part in Class Alive Body
  #Code goes here

func _process_alive(delta) -> void:
  pass

func _process_dead(delta) -> void:
  pass

func _kill(killer: Node2D): #Why is this giving me an error? #Call this function you need with param self <ENEMYNAME>._kill(self) @reflexguru
  ._kill(killer)
  if killer is AliveBody:
    killer = killer as AliveBody
    match killer.kill_as:
      DEATH_TYPE.BASIC:
        #TODO: death types @reflexguru
        pass
      DEATH_TYPE.FALL:
        pass
      DEATH_TYPE.DISAPPEAR:
        pass