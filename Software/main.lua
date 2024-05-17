hours=5
minutes=6
seconds=3
function Seg7(A3,A2,A1,A0)
    LIB_GpioWrite("D5",A0)
	LIB_GpioWrite("D6",A1)
	LIB_GpioWrite("D7",A2)
	LIB_GpioWrite("D9",A3)
end
function Figures(bit1)
  if bit1>=0 and bit1<1 then
  Seg7(0,0,0,0)
  elseif bit1>=1 and bit1<2 then
  Seg7(0,0,0,1)
  elseif bit1>=2 and bit1<3 then
  Seg7(0,0,1,0)
  elseif bit1>=3 and bit1<4 then
  Seg7(0,0,1,1)
  elseif bit1>=4 and bit1<5 then
  Seg7(0,1,0,0)
  elseif bit1>=5 and bit1<6 then
  Seg7(0,1,0,1)
  elseif bit1>=6 and bit1<7 then
  Seg7(0,1,1,0)
  elseif bit1>=7 and bit1<8 then
  Seg7(0,1,1,1)
  elseif bit1>=8 and bit1<9 then
  Seg7(1,0,0,0)
  elseif bit1>=9 and bit1<10 then
  Seg7(1,0,0,1)
  end
end
function SELECT(bit2)
  if bit2==1 then
  LIB_GpioWrite("D3",1)
  elseif  bit2==2  then
  LIB_GpioWrite("D1",1)
  elseif  bit2==3  then
  LIB_GpioWrite("D0",1)
  elseif  bit2==4  then
  LIB_GpioWrite("D8",1)
  elseif  bit2==5  then
  LIB_GpioWrite("D10",1)
  elseif  bit2==6  then
  LIB_GpioWrite("D11",1)
  end
end
function SELECTclr()
  LIB_GpioWrite("D3",0)
  LIB_GpioWrite("D1",0)
  LIB_GpioWrite("D0",0)
  LIB_GpioWrite("D8",0)
  LIB_GpioWrite("D10",0)
  LIB_GpioWrite("D11",0)
end
function DEC_BCD(dec)
  return (dec+(dec/10)*6)
end

function I2C_DS3231_SetTime(hour,minute,second)
--定义一个数组
  command = {}
  str=tostring(hour)
  if  hour<10 then
  str="020"..str
  else
  str="02"..str
  end
  command = LIB_HexStrToHexTab(str)
  LIB_IIC0Write(0x68,command)
  

  str=tostring(minute)
  if  minute<10 then
  str="010"..str
  else
  str="01"..str
  end
  command = LIB_HexStrToHexTab(str)
  LIB_IIC0Write(0x68,command)
  

  str=tostring(second)
  if  seconds<10 then
  str="000"..str
  else
  str="00"..str
  end
  command = LIB_HexStrToHexTab(str)
  LIB_IIC0Write(0x68,command)
end

function I2C_DS3231_getTime()
    command = {}
    command[1] = 0x02
    LIB_IIC0Write(0x68,command)
	result,data = LIB_IIC0Read(0x68,1)
	if result == 1 then
    str = LIB_HexTabToHexStr(data)	
	hours=tonumber(str)
	end
	
	command[1] = 0x01
    LIB_IIC0Write(0x68,command)
	result,data = LIB_IIC0Read(0x68,1)
	if result == 1 then
	str = LIB_HexTabToHexStr(data)	
	minutes=tonumber(str)
    end
	
	command[1] = 0x00
    LIB_IIC0Write(0x68,command)
	result,data = LIB_IIC0Read(0x68,1)
	if result == 1 then
	str = LIB_HexTabToHexStr(data)
	seconds=tonumber(str)
	end
end
--定义10毫秒定时器的回调函数，函数名字必须是LIB_10msTimerCallback
function LIB_10msTimerCallback()
    timer_ms = timer_ms + 10
end
--配置D0,D1,D3为普通GPIO输出
LIB_GpioOutputConfig("D0","STANDARD")
LIB_GpioOutputConfig("D1","STANDARD")
LIB_GpioOutputConfig("D2","STANDARD")
LIB_GpioOutputConfig("D3","STANDARD")
LIB_GpioOutputConfig("D4","STANDARD")
LIB_GpioOutputConfig("D5","STANDARD")
LIB_GpioOutputConfig("D6","STANDARD")
LIB_GpioOutputConfig("D7","STANDARD")
LIB_GpioOutputConfig("D8","STANDARD")
LIB_GpioOutputConfig("D9","STANDARD")
LIB_GpioOutputConfig("D10","STANDARD")
LIB_GpioOutputConfig("D11","STANDARD")
--使能系统10毫秒定时器开始工作
timer_ms = 0
LIB_10msTimerConfig("ENABLE")
--配置GPS模块开始工作，占用TX0和RX0引脚
LIB_NEO6MConfig("UART0")
LIB_SystemLogEnable() --查看详细日志(log.txt)时打开
--配置IIC0以400Khz的频率开始工作
LIB_IIC0Config("400K")
LIB_GpioWrite("D4",0)
LIB_GpioWrite("D2",1)
openflag=1
while(GC(1) == true)
do
	--上电后通过GPS同步一次UTC时间更新到DS3231时钟芯片
    if  openflag==1  then
		--查询是否解析到GPS数据
		flag,lo,la,al,utc = LIB_NEO6MGetGpsData()
		if flag == 1 then
			--将读取到的经度、纬度、海拔、UTC时间打印输出
			--print(string.format("longtitue:%f latitue:%f altitue:%.0fm UTC:%d", lo,la,al,utc))
			--将从GPS获取的时间设置为Core自身的系统时间
			LIB_SetUtcTime(utc)
			y,mo,d,h,mi,s,ms = LIB_GetDateTime()
			h=h+8 --转成北京时间（东八区）
			--print(string.format("h:%d m:%d s:%d", h,mi,s))
			I2C_DS3231_SetTime(h,mi,s)
			openflag=0
		end
	end
	
	--从DS3231时钟芯片获取时间并显示
	I2C_DS3231_getTime()
	if s~=seconds then
	  SELECT(6)
	  Figures(seconds%10)
	  SELECTclr()
	end
	if s1~=(seconds-seconds%10)/10 then
	  SELECT(5)
	  Figures(seconds/10)
	  SELECTclr()
	end
	if m~=minutes then
	  SELECT(4)
	  Figures(minutes%10)
	  SELECTclr()
	end
	if m1~=(minutes-minutes%10)/10 then
	  SELECT(3)
	  Figures(minutes/10)
	  SELECTclr()
	end
	if h~=hours then
	  SELECT(2)
	  Figures(hours%10)
	  SELECTclr()
	end
	if h1~=(hours-hours%10)/10 then
	  SELECT(1)
	  Figures(hours/10)
	  SELECTclr()
	end
	h=hours
	h1=(hours-hours%10)/10
	m=minutes
	m1=(minutes-minutes%10)/10
	s=seconds
	s1=(seconds-seconds%10)/10
end

    
