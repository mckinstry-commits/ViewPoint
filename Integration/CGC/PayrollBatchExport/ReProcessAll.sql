USE MCK_INTEGRATION
go

DECLARE prcur CURSOR for
SELECT DISTINCT 
	GPCONO, GPBT05, GPDTWE 
FROM 
	cgcPRPWKD
ORDER BY 
	GPCONO,GPDTWE,GPBT05
FOR READ ONLY

SET NOCOUNT ON

DECLARE @srcCompanyNumber	decimal(2,0)
DECLARE @srcBatchNumber	decimal(5,0)
DECLARE @srcWeekEnding		NUMERIC(8,0)
DECLARE @rcnt int
DECLARE @cmdSQL		VARCHAR(255)

SELECT @rcnt=0

OPEN prcur
FETCH prcur INTO
	@srcCompanyNumber,@srcBatchNumber,@srcWeekEnding

WHILE @@fetch_status=0
BEGIN
	SELECT @rcnt=@rcnt + 1
	SELECT 
		@cmdSQL='exec mspGetCgcPayrollBatch '
	+	'@CompanyNumber=' + CAST(@srcCompanyNumber AS VARCHAR(10)) + ', '
	+	'@BatchNumber=' + CAST(@srcBatchNumber AS VARCHAR(10)) + ', '
	+	'@WeekEnding=' + CAST(@srcWeekEnding AS VARCHAR(10)) + ', '
	+	'@DoRefresh=0'  
	+	'     -- ' + CAST(@rcnt AS VARCHAR(10))

	PRINT @cmdSQL
	PRINT 'go'
	
	FETCH prcur INTO
		@srcCompanyNumber,@srcBatchNumber,@srcWeekEnding
END
CLOSE prcur 
DEALLOCATE prcur
GO






exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140511, @DoRefresh=0     -- 1
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140511, @DoRefresh=0     -- 2
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140511, @DoRefresh=0     -- 3
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140511, @DoRefresh=0     -- 4
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140511, @DoRefresh=0     -- 5
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140511, @DoRefresh=0     -- 6
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=40, @WeekEnding=20140511, @DoRefresh=0     -- 7
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140511, @DoRefresh=0     -- 8
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140511, @DoRefresh=0     -- 9
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=53, @WeekEnding=20140511, @DoRefresh=0     -- 10
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140511, @DoRefresh=0     -- 11
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140511, @DoRefresh=0     -- 12
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140518, @DoRefresh=0     -- 13
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140518, @DoRefresh=0     -- 14
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140518, @DoRefresh=0     -- 15
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140518, @DoRefresh=0     -- 16
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=8, @WeekEnding=20140518, @DoRefresh=0     -- 17
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=9, @WeekEnding=20140518, @DoRefresh=0     -- 18
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140518, @DoRefresh=0     -- 19
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140518, @DoRefresh=0     -- 20
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140518, @DoRefresh=0     -- 21
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140518, @DoRefresh=0     -- 22
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=16, @WeekEnding=20140518, @DoRefresh=0     -- 23
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140518, @DoRefresh=0     -- 24
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140518, @DoRefresh=0     -- 25
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140518, @DoRefresh=0     -- 26
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140518, @DoRefresh=0     -- 27
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=40, @WeekEnding=20140518, @DoRefresh=0     -- 28
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140518, @DoRefresh=0     -- 29
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140518, @DoRefresh=0     -- 30
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=53, @WeekEnding=20140518, @DoRefresh=0     -- 31
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140518, @DoRefresh=0     -- 32
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=191, @WeekEnding=20140518, @DoRefresh=0     -- 33
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=290, @WeekEnding=20140518, @DoRefresh=0     -- 34
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=380, @WeekEnding=20140518, @DoRefresh=0     -- 35
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=520, @WeekEnding=20140518, @DoRefresh=0     -- 36
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=521, @WeekEnding=20140518, @DoRefresh=0     -- 37
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140518, @DoRefresh=0     -- 38
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=699, @WeekEnding=20140518, @DoRefresh=0     -- 39
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=10953, @WeekEnding=20140518, @DoRefresh=0     -- 40
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11209, @WeekEnding=20140518, @DoRefresh=0     -- 41
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52531, @WeekEnding=20140518, @DoRefresh=0     -- 42
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52532, @WeekEnding=20140518, @DoRefresh=0     -- 43
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52533, @WeekEnding=20140518, @DoRefresh=0     -- 44
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52534, @WeekEnding=20140518, @DoRefresh=0     -- 45
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52535, @WeekEnding=20140518, @DoRefresh=0     -- 46
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140601, @DoRefresh=0     -- 47
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140601, @DoRefresh=0     -- 48
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140601, @DoRefresh=0     -- 49
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=8, @WeekEnding=20140601, @DoRefresh=0     -- 50
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=9, @WeekEnding=20140601, @DoRefresh=0     -- 51
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140601, @DoRefresh=0     -- 52
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140601, @DoRefresh=0     -- 53
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140601, @DoRefresh=0     -- 54
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140601, @DoRefresh=0     -- 55
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=16, @WeekEnding=20140601, @DoRefresh=0     -- 56
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140601, @DoRefresh=0     -- 57
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140601, @DoRefresh=0     -- 58
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140601, @DoRefresh=0     -- 59
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140601, @DoRefresh=0     -- 60
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=38, @WeekEnding=20140601, @DoRefresh=0     -- 61
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=40, @WeekEnding=20140601, @DoRefresh=0     -- 62
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140601, @DoRefresh=0     -- 63
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140601, @DoRefresh=0     -- 64
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=53, @WeekEnding=20140601, @DoRefresh=0     -- 65
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140601, @DoRefresh=0     -- 66
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=290, @WeekEnding=20140601, @DoRefresh=0     -- 67
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=411, @WeekEnding=20140601, @DoRefresh=0     -- 68
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=412, @WeekEnding=20140601, @DoRefresh=0     -- 69
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=413, @WeekEnding=20140601, @DoRefresh=0     -- 70
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=414, @WeekEnding=20140601, @DoRefresh=0     -- 71
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=415, @WeekEnding=20140601, @DoRefresh=0     -- 72
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=532, @WeekEnding=20140601, @DoRefresh=0     -- 73
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140601, @DoRefresh=0     -- 74
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=602, @WeekEnding=20140601, @DoRefresh=0     -- 75
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=603, @WeekEnding=20140601, @DoRefresh=0     -- 76
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=699, @WeekEnding=20140601, @DoRefresh=0     -- 77
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1750, @WeekEnding=20140601, @DoRefresh=0     -- 78
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4101, @WeekEnding=20140601, @DoRefresh=0     -- 79
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4102, @WeekEnding=20140601, @DoRefresh=0     -- 80
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11119, @WeekEnding=20140601, @DoRefresh=0     -- 81
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11242, @WeekEnding=20140601, @DoRefresh=0     -- 82
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52541, @WeekEnding=20140601, @DoRefresh=0     -- 83
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52542, @WeekEnding=20140601, @DoRefresh=0     -- 84
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52543, @WeekEnding=20140601, @DoRefresh=0     -- 85
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52544, @WeekEnding=20140601, @DoRefresh=0     -- 86
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52545, @WeekEnding=20140601, @DoRefresh=0     -- 87
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140608, @DoRefresh=0     -- 88
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140608, @DoRefresh=0     -- 89
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140608, @DoRefresh=0     -- 90
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140608, @DoRefresh=0     -- 91
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=8, @WeekEnding=20140608, @DoRefresh=0     -- 92
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=9, @WeekEnding=20140608, @DoRefresh=0     -- 93
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140608, @DoRefresh=0     -- 94
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140608, @DoRefresh=0     -- 95
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140608, @DoRefresh=0     -- 96
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140608, @DoRefresh=0     -- 97
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=16, @WeekEnding=20140608, @DoRefresh=0     -- 98
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140608, @DoRefresh=0     -- 99
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140608, @DoRefresh=0     -- 100
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140608, @DoRefresh=0     -- 101
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140608, @DoRefresh=0     -- 102
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140608, @DoRefresh=0     -- 103
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140608, @DoRefresh=0     -- 104
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=53, @WeekEnding=20140608, @DoRefresh=0     -- 105
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140608, @DoRefresh=0     -- 106
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=411, @WeekEnding=20140608, @DoRefresh=0     -- 107
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=412, @WeekEnding=20140608, @DoRefresh=0     -- 108
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=413, @WeekEnding=20140608, @DoRefresh=0     -- 109
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=414, @WeekEnding=20140608, @DoRefresh=0     -- 110
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=415, @WeekEnding=20140608, @DoRefresh=0     -- 111
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140608, @DoRefresh=0     -- 112
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=610, @WeekEnding=20140608, @DoRefresh=0     -- 113
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=611, @WeekEnding=20140608, @DoRefresh=0     -- 114
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=699, @WeekEnding=20140608, @DoRefresh=0     -- 115
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4101, @WeekEnding=20140608, @DoRefresh=0     -- 116
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4102, @WeekEnding=20140608, @DoRefresh=0     -- 117
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11028, @WeekEnding=20140608, @DoRefresh=0     -- 118
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11223, @WeekEnding=20140608, @DoRefresh=0     -- 119
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52546, @WeekEnding=20140608, @DoRefresh=0     -- 120
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52547, @WeekEnding=20140608, @DoRefresh=0     -- 121
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52548, @WeekEnding=20140608, @DoRefresh=0     -- 122
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52549, @WeekEnding=20140608, @DoRefresh=0     -- 123
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52550, @WeekEnding=20140608, @DoRefresh=0     -- 124
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140615, @DoRefresh=0     -- 125
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140615, @DoRefresh=0     -- 126
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140615, @DoRefresh=0     -- 127
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140615, @DoRefresh=0     -- 128
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=8, @WeekEnding=20140615, @DoRefresh=0     -- 129
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140615, @DoRefresh=0     -- 130
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140615, @DoRefresh=0     -- 131
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140615, @DoRefresh=0     -- 132
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140615, @DoRefresh=0     -- 133
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=16, @WeekEnding=20140615, @DoRefresh=0     -- 134
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140615, @DoRefresh=0     -- 135
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140615, @DoRefresh=0     -- 136
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140615, @DoRefresh=0     -- 137
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140615, @DoRefresh=0     -- 138
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=40, @WeekEnding=20140615, @DoRefresh=0     -- 139
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140615, @DoRefresh=0     -- 140
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140615, @DoRefresh=0     -- 141
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=53, @WeekEnding=20140615, @DoRefresh=0     -- 142
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=60, @WeekEnding=20140615, @DoRefresh=0     -- 143
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140615, @DoRefresh=0     -- 144
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=101, @WeekEnding=20140615, @DoRefresh=0     -- 145
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=380, @WeekEnding=20140615, @DoRefresh=0     -- 146
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=411, @WeekEnding=20140615, @DoRefresh=0     -- 147
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=412, @WeekEnding=20140615, @DoRefresh=0     -- 148
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=413, @WeekEnding=20140615, @DoRefresh=0     -- 149
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=414, @WeekEnding=20140615, @DoRefresh=0     -- 150
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=415, @WeekEnding=20140615, @DoRefresh=0     -- 151
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140615, @DoRefresh=0     -- 152
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=617, @WeekEnding=20140615, @DoRefresh=0     -- 153
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=618, @WeekEnding=20140615, @DoRefresh=0     -- 154
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=660, @WeekEnding=20140615, @DoRefresh=0     -- 155
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=699, @WeekEnding=20140615, @DoRefresh=0     -- 156
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4101, @WeekEnding=20140615, @DoRefresh=0     -- 157
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4102, @WeekEnding=20140615, @DoRefresh=0     -- 158
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=10156, @WeekEnding=20140615, @DoRefresh=0     -- 159
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=10946, @WeekEnding=20140615, @DoRefresh=0     -- 160
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52551, @WeekEnding=20140615, @DoRefresh=0     -- 161
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52552, @WeekEnding=20140615, @DoRefresh=0     -- 162
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52553, @WeekEnding=20140615, @DoRefresh=0     -- 163
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52554, @WeekEnding=20140615, @DoRefresh=0     -- 164
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52555, @WeekEnding=20140615, @DoRefresh=0     -- 165
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140622, @DoRefresh=0     -- 166
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140622, @DoRefresh=0     -- 167
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140622, @DoRefresh=0     -- 168
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140622, @DoRefresh=0     -- 169
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=8, @WeekEnding=20140622, @DoRefresh=0     -- 170
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=9, @WeekEnding=20140622, @DoRefresh=0     -- 171
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140622, @DoRefresh=0     -- 172
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140622, @DoRefresh=0     -- 173
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140622, @DoRefresh=0     -- 174
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140622, @DoRefresh=0     -- 175
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=16, @WeekEnding=20140622, @DoRefresh=0     -- 176
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140622, @DoRefresh=0     -- 177
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140622, @DoRefresh=0     -- 178
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140622, @DoRefresh=0     -- 179
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=21, @WeekEnding=20140622, @DoRefresh=0     -- 180
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140622, @DoRefresh=0     -- 181
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=40, @WeekEnding=20140622, @DoRefresh=0     -- 182
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=46, @WeekEnding=20140622, @DoRefresh=0     -- 183
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140622, @DoRefresh=0     -- 184
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140622, @DoRefresh=0     -- 185
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=53, @WeekEnding=20140622, @DoRefresh=0     -- 186
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=60, @WeekEnding=20140622, @DoRefresh=0     -- 187
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140622, @DoRefresh=0     -- 188
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=191, @WeekEnding=20140622, @DoRefresh=0     -- 189
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=280, @WeekEnding=20140622, @DoRefresh=0     -- 190
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=411, @WeekEnding=20140622, @DoRefresh=0     -- 191
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=412, @WeekEnding=20140622, @DoRefresh=0     -- 192
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=413, @WeekEnding=20140622, @DoRefresh=0     -- 193
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=414, @WeekEnding=20140622, @DoRefresh=0     -- 194
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=415, @WeekEnding=20140622, @DoRefresh=0     -- 195
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140622, @DoRefresh=0     -- 196
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=623, @WeekEnding=20140622, @DoRefresh=0     -- 197
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=624, @WeekEnding=20140622, @DoRefresh=0     -- 198
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=625, @WeekEnding=20140622, @DoRefresh=0     -- 199
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=660, @WeekEnding=20140622, @DoRefresh=0     -- 200
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=699, @WeekEnding=20140622, @DoRefresh=0     -- 201
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4101, @WeekEnding=20140622, @DoRefresh=0     -- 202
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4102, @WeekEnding=20140622, @DoRefresh=0     -- 203
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11010, @WeekEnding=20140622, @DoRefresh=0     -- 204
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11118, @WeekEnding=20140622, @DoRefresh=0     -- 205
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52556, @WeekEnding=20140622, @DoRefresh=0     -- 206
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52557, @WeekEnding=20140622, @DoRefresh=0     -- 207
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52558, @WeekEnding=20140622, @DoRefresh=0     -- 208
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52559, @WeekEnding=20140622, @DoRefresh=0     -- 209
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52563, @WeekEnding=20140622, @DoRefresh=0     -- 210
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140629, @DoRefresh=0     -- 211
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140629, @DoRefresh=0     -- 212
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140629, @DoRefresh=0     -- 213
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140629, @DoRefresh=0     -- 214
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=8, @WeekEnding=20140629, @DoRefresh=0     -- 215
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=9, @WeekEnding=20140629, @DoRefresh=0     -- 216
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140629, @DoRefresh=0     -- 217
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140629, @DoRefresh=0     -- 218
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140629, @DoRefresh=0     -- 219
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140629, @DoRefresh=0     -- 220
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=16, @WeekEnding=20140629, @DoRefresh=0     -- 221
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140629, @DoRefresh=0     -- 222
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140629, @DoRefresh=0     -- 223
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140629, @DoRefresh=0     -- 224
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140629, @DoRefresh=0     -- 225
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=40, @WeekEnding=20140629, @DoRefresh=0     -- 226
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140629, @DoRefresh=0     -- 227
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140629, @DoRefresh=0     -- 228
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=53, @WeekEnding=20140629, @DoRefresh=0     -- 229
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=60, @WeekEnding=20140629, @DoRefresh=0     -- 230
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140629, @DoRefresh=0     -- 231
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=380, @WeekEnding=20140629, @DoRefresh=0     -- 232
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=411, @WeekEnding=20140629, @DoRefresh=0     -- 233
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=412, @WeekEnding=20140629, @DoRefresh=0     -- 234
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=413, @WeekEnding=20140629, @DoRefresh=0     -- 235
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=414, @WeekEnding=20140629, @DoRefresh=0     -- 236
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=415, @WeekEnding=20140629, @DoRefresh=0     -- 237
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140629, @DoRefresh=0     -- 238
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=630, @WeekEnding=20140629, @DoRefresh=0     -- 239
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=660, @WeekEnding=20140629, @DoRefresh=0     -- 240
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=699, @WeekEnding=20140629, @DoRefresh=0     -- 241
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=701, @WeekEnding=20140629, @DoRefresh=0     -- 242
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4101, @WeekEnding=20140629, @DoRefresh=0     -- 243
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4102, @WeekEnding=20140629, @DoRefresh=0     -- 244
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=10922, @WeekEnding=20140629, @DoRefresh=0     -- 245
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11033, @WeekEnding=20140629, @DoRefresh=0     -- 246
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52564, @WeekEnding=20140629, @DoRefresh=0     -- 247
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52565, @WeekEnding=20140629, @DoRefresh=0     -- 248
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52566, @WeekEnding=20140629, @DoRefresh=0     -- 249
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52567, @WeekEnding=20140629, @DoRefresh=0     -- 250
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52568, @WeekEnding=20140629, @DoRefresh=0     -- 251
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=95345, @WeekEnding=20140629, @DoRefresh=0     -- 252
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140706, @DoRefresh=0     -- 253
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140706, @DoRefresh=0     -- 254
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140706, @DoRefresh=0     -- 255
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140706, @DoRefresh=0     -- 256
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=8, @WeekEnding=20140706, @DoRefresh=0     -- 257
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=9, @WeekEnding=20140706, @DoRefresh=0     -- 258
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140706, @DoRefresh=0     -- 259
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140706, @DoRefresh=0     -- 260
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140706, @DoRefresh=0     -- 261
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140706, @DoRefresh=0     -- 262
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=16, @WeekEnding=20140706, @DoRefresh=0     -- 263
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140706, @DoRefresh=0     -- 264
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140706, @DoRefresh=0     -- 265
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140706, @DoRefresh=0     -- 266
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140706, @DoRefresh=0     -- 267
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=32, @WeekEnding=20140706, @DoRefresh=0     -- 268
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=40, @WeekEnding=20140706, @DoRefresh=0     -- 269
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140706, @DoRefresh=0     -- 270
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140706, @DoRefresh=0     -- 271
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=53, @WeekEnding=20140706, @DoRefresh=0     -- 272
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=60, @WeekEnding=20140706, @DoRefresh=0     -- 273
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140706, @DoRefresh=0     -- 274
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=411, @WeekEnding=20140706, @DoRefresh=0     -- 275
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=412, @WeekEnding=20140706, @DoRefresh=0     -- 276
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=413, @WeekEnding=20140706, @DoRefresh=0     -- 277
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=414, @WeekEnding=20140706, @DoRefresh=0     -- 278
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=415, @WeekEnding=20140706, @DoRefresh=0     -- 279
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140706, @DoRefresh=0     -- 280
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=660, @WeekEnding=20140706, @DoRefresh=0     -- 281
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=699, @WeekEnding=20140706, @DoRefresh=0     -- 282
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=708, @WeekEnding=20140706, @DoRefresh=0     -- 283
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=709, @WeekEnding=20140706, @DoRefresh=0     -- 284
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4101, @WeekEnding=20140706, @DoRefresh=0     -- 285
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4102, @WeekEnding=20140706, @DoRefresh=0     -- 286
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11107, @WeekEnding=20140706, @DoRefresh=0     -- 287
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11249, @WeekEnding=20140706, @DoRefresh=0     -- 288
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52569, @WeekEnding=20140706, @DoRefresh=0     -- 289
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52570, @WeekEnding=20140706, @DoRefresh=0     -- 290
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52571, @WeekEnding=20140706, @DoRefresh=0     -- 291
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52572, @WeekEnding=20140706, @DoRefresh=0     -- 292
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52573, @WeekEnding=20140706, @DoRefresh=0     -- 293
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=95384, @WeekEnding=20140706, @DoRefresh=0     -- 294
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140713, @DoRefresh=0     -- 295
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140713, @DoRefresh=0     -- 296
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140713, @DoRefresh=0     -- 297
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140713, @DoRefresh=0     -- 298
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=8, @WeekEnding=20140713, @DoRefresh=0     -- 299
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=9, @WeekEnding=20140713, @DoRefresh=0     -- 300
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140713, @DoRefresh=0     -- 301
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140713, @DoRefresh=0     -- 302
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140713, @DoRefresh=0     -- 303
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140713, @DoRefresh=0     -- 304
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=16, @WeekEnding=20140713, @DoRefresh=0     -- 305
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140713, @DoRefresh=0     -- 306
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140713, @DoRefresh=0     -- 307
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140713, @DoRefresh=0     -- 308
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140713, @DoRefresh=0     -- 309
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=40, @WeekEnding=20140713, @DoRefresh=0     -- 310
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=46, @WeekEnding=20140713, @DoRefresh=0     -- 311
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140713, @DoRefresh=0     -- 312
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140713, @DoRefresh=0     -- 313
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=53, @WeekEnding=20140713, @DoRefresh=0     -- 314
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=60, @WeekEnding=20140713, @DoRefresh=0     -- 315
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140713, @DoRefresh=0     -- 316
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=411, @WeekEnding=20140713, @DoRefresh=0     -- 317
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=412, @WeekEnding=20140713, @DoRefresh=0     -- 318
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=414, @WeekEnding=20140713, @DoRefresh=0     -- 319
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=415, @WeekEnding=20140713, @DoRefresh=0     -- 320
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140713, @DoRefresh=0     -- 321
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=699, @WeekEnding=20140713, @DoRefresh=0     -- 322
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=715, @WeekEnding=20140713, @DoRefresh=0     -- 323
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=716, @WeekEnding=20140713, @DoRefresh=0     -- 324
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=2056, @WeekEnding=20140713, @DoRefresh=0     -- 325
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4101, @WeekEnding=20140713, @DoRefresh=0     -- 326
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4102, @WeekEnding=20140713, @DoRefresh=0     -- 327
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=10922, @WeekEnding=20140713, @DoRefresh=0     -- 328
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=10953, @WeekEnding=20140713, @DoRefresh=0     -- 329
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52574, @WeekEnding=20140713, @DoRefresh=0     -- 330
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52575, @WeekEnding=20140713, @DoRefresh=0     -- 331
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52576, @WeekEnding=20140713, @DoRefresh=0     -- 332
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52577, @WeekEnding=20140713, @DoRefresh=0     -- 333
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52578, @WeekEnding=20140713, @DoRefresh=0     -- 334
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140720, @DoRefresh=0     -- 335
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140720, @DoRefresh=0     -- 336
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140720, @DoRefresh=0     -- 337
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140720, @DoRefresh=0     -- 338
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=8, @WeekEnding=20140720, @DoRefresh=0     -- 339
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140720, @DoRefresh=0     -- 340
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140720, @DoRefresh=0     -- 341
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140720, @DoRefresh=0     -- 342
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140720, @DoRefresh=0     -- 343
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=16, @WeekEnding=20140720, @DoRefresh=0     -- 344
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140720, @DoRefresh=0     -- 345
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140720, @DoRefresh=0     -- 346
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140720, @DoRefresh=0     -- 347
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140720, @DoRefresh=0     -- 348
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=32, @WeekEnding=20140720, @DoRefresh=0     -- 349
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140720, @DoRefresh=0     -- 350
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140720, @DoRefresh=0     -- 351
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=53, @WeekEnding=20140720, @DoRefresh=0     -- 352
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140720, @DoRefresh=0     -- 353
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=101, @WeekEnding=20140720, @DoRefresh=0     -- 354
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=191, @WeekEnding=20140720, @DoRefresh=0     -- 355
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=280, @WeekEnding=20140720, @DoRefresh=0     -- 356
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=411, @WeekEnding=20140720, @DoRefresh=0     -- 357
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=412, @WeekEnding=20140720, @DoRefresh=0     -- 358
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=414, @WeekEnding=20140720, @DoRefresh=0     -- 359
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140720, @DoRefresh=0     -- 360
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=699, @WeekEnding=20140720, @DoRefresh=0     -- 361
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=715, @WeekEnding=20140720, @DoRefresh=0     -- 362
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=716, @WeekEnding=20140720, @DoRefresh=0     -- 363
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=717, @WeekEnding=20140720, @DoRefresh=0     -- 364
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1263, @WeekEnding=20140720, @DoRefresh=0     -- 365
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=2083, @WeekEnding=20140720, @DoRefresh=0     -- 366
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4101, @WeekEnding=20140720, @DoRefresh=0     -- 367
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4102, @WeekEnding=20140720, @DoRefresh=0     -- 368
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=10219, @WeekEnding=20140720, @DoRefresh=0     -- 369
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11035, @WeekEnding=20140720, @DoRefresh=0     -- 370
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=17619, @WeekEnding=20140720, @DoRefresh=0     -- 371
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52579, @WeekEnding=20140720, @DoRefresh=0     -- 372
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52580, @WeekEnding=20140720, @DoRefresh=0     -- 373
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52581, @WeekEnding=20140720, @DoRefresh=0     -- 374
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52582, @WeekEnding=20140720, @DoRefresh=0     -- 375
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52583, @WeekEnding=20140720, @DoRefresh=0     -- 376
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140727, @DoRefresh=0     -- 377
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140727, @DoRefresh=0     -- 378
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140727, @DoRefresh=0     -- 379
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=8, @WeekEnding=20140727, @DoRefresh=0     -- 380
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140727, @DoRefresh=0     -- 381
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140727, @DoRefresh=0     -- 382
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140727, @DoRefresh=0     -- 383
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140727, @DoRefresh=0     -- 384
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140727, @DoRefresh=0     -- 385
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140727, @DoRefresh=0     -- 386
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140727, @DoRefresh=0     -- 387
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=21, @WeekEnding=20140727, @DoRefresh=0     -- 388
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140727, @DoRefresh=0     -- 389
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=32, @WeekEnding=20140727, @DoRefresh=0     -- 390
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=40, @WeekEnding=20140727, @DoRefresh=0     -- 391
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140727, @DoRefresh=0     -- 392
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140727, @DoRefresh=0     -- 393
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=53, @WeekEnding=20140727, @DoRefresh=0     -- 394
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=60, @WeekEnding=20140727, @DoRefresh=0     -- 395
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=380, @WeekEnding=20140727, @DoRefresh=0     -- 396
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=411, @WeekEnding=20140727, @DoRefresh=0     -- 397
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=412, @WeekEnding=20140727, @DoRefresh=0     -- 398
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=413, @WeekEnding=20140727, @DoRefresh=0     -- 399
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140727, @DoRefresh=0     -- 400
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=660, @WeekEnding=20140727, @DoRefresh=0     -- 401
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=699, @WeekEnding=20140727, @DoRefresh=0     -- 402
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=729, @WeekEnding=20140727, @DoRefresh=0     -- 403
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4101, @WeekEnding=20140727, @DoRefresh=0     -- 404
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4102, @WeekEnding=20140727, @DoRefresh=0     -- 405
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4103, @WeekEnding=20140727, @DoRefresh=0     -- 406
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11206, @WeekEnding=20140727, @DoRefresh=0     -- 407
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52584, @WeekEnding=20140727, @DoRefresh=0     -- 408
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52585, @WeekEnding=20140727, @DoRefresh=0     -- 409
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52586, @WeekEnding=20140727, @DoRefresh=0     -- 410
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52587, @WeekEnding=20140727, @DoRefresh=0     -- 411
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52588, @WeekEnding=20140727, @DoRefresh=0     -- 412
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140803, @DoRefresh=0     -- 413
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140803, @DoRefresh=0     -- 414
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140803, @DoRefresh=0     -- 415
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140803, @DoRefresh=0     -- 416
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=8, @WeekEnding=20140803, @DoRefresh=0     -- 417
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140803, @DoRefresh=0     -- 418
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140803, @DoRefresh=0     -- 419
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140803, @DoRefresh=0     -- 420
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140803, @DoRefresh=0     -- 421
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140803, @DoRefresh=0     -- 422
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140803, @DoRefresh=0     -- 423
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140803, @DoRefresh=0     -- 424
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=21, @WeekEnding=20140803, @DoRefresh=0     -- 425
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140803, @DoRefresh=0     -- 426
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=32, @WeekEnding=20140803, @DoRefresh=0     -- 427
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=40, @WeekEnding=20140803, @DoRefresh=0     -- 428
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140803, @DoRefresh=0     -- 429
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140803, @DoRefresh=0     -- 430
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=53, @WeekEnding=20140803, @DoRefresh=0     -- 431
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=60, @WeekEnding=20140803, @DoRefresh=0     -- 432
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140803, @DoRefresh=0     -- 433
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=101, @WeekEnding=20140803, @DoRefresh=0     -- 434
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=411, @WeekEnding=20140803, @DoRefresh=0     -- 435
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=412, @WeekEnding=20140803, @DoRefresh=0     -- 436
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=413, @WeekEnding=20140803, @DoRefresh=0     -- 437
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140803, @DoRefresh=0     -- 438
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=669, @WeekEnding=20140803, @DoRefresh=0     -- 439
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=805, @WeekEnding=20140803, @DoRefresh=0     -- 440
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=806, @WeekEnding=20140803, @DoRefresh=0     -- 441
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4101, @WeekEnding=20140803, @DoRefresh=0     -- 442
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4102, @WeekEnding=20140803, @DoRefresh=0     -- 443
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11014, @WeekEnding=20140803, @DoRefresh=0     -- 444
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11138, @WeekEnding=20140803, @DoRefresh=0     -- 445
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52589, @WeekEnding=20140803, @DoRefresh=0     -- 446
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52590, @WeekEnding=20140803, @DoRefresh=0     -- 447
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52591, @WeekEnding=20140803, @DoRefresh=0     -- 448
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52592, @WeekEnding=20140803, @DoRefresh=0     -- 449
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52593, @WeekEnding=20140803, @DoRefresh=0     -- 450
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140810, @DoRefresh=0     -- 451
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140810, @DoRefresh=0     -- 452
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140810, @DoRefresh=0     -- 453
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140810, @DoRefresh=0     -- 454
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=8, @WeekEnding=20140810, @DoRefresh=0     -- 455
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140810, @DoRefresh=0     -- 456
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140810, @DoRefresh=0     -- 457
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140810, @DoRefresh=0     -- 458
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140810, @DoRefresh=0     -- 459
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140810, @DoRefresh=0     -- 460
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140810, @DoRefresh=0     -- 461
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140810, @DoRefresh=0     -- 462
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140810, @DoRefresh=0     -- 463
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=40, @WeekEnding=20140810, @DoRefresh=0     -- 464
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140810, @DoRefresh=0     -- 465
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140810, @DoRefresh=0     -- 466
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=53, @WeekEnding=20140810, @DoRefresh=0     -- 467
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=60, @WeekEnding=20140810, @DoRefresh=0     -- 468
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140810, @DoRefresh=0     -- 469
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=101, @WeekEnding=20140810, @DoRefresh=0     -- 470
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=191, @WeekEnding=20140810, @DoRefresh=0     -- 471
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=411, @WeekEnding=20140810, @DoRefresh=0     -- 472
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=412, @WeekEnding=20140810, @DoRefresh=0     -- 473
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=413, @WeekEnding=20140810, @DoRefresh=0     -- 474
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140810, @DoRefresh=0     -- 475
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=660, @WeekEnding=20140810, @DoRefresh=0     -- 476
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=699, @WeekEnding=20140810, @DoRefresh=0     -- 477
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=811, @WeekEnding=20140810, @DoRefresh=0     -- 478
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=812, @WeekEnding=20140810, @DoRefresh=0     -- 479
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=2163, @WeekEnding=20140810, @DoRefresh=0     -- 480
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4101, @WeekEnding=20140810, @DoRefresh=0     -- 481
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4102, @WeekEnding=20140810, @DoRefresh=0     -- 482
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=10948, @WeekEnding=20140810, @DoRefresh=0     -- 483
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11241, @WeekEnding=20140810, @DoRefresh=0     -- 484
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=36318, @WeekEnding=20140810, @DoRefresh=0     -- 485
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=41021, @WeekEnding=20140810, @DoRefresh=0     -- 486
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52594, @WeekEnding=20140810, @DoRefresh=0     -- 487
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52596, @WeekEnding=20140810, @DoRefresh=0     -- 488
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52597, @WeekEnding=20140810, @DoRefresh=0     -- 489
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52599, @WeekEnding=20140810, @DoRefresh=0     -- 490
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52604, @WeekEnding=20140810, @DoRefresh=0     -- 491
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140817, @DoRefresh=0     -- 492
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140817, @DoRefresh=0     -- 493
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140817, @DoRefresh=0     -- 494
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140817, @DoRefresh=0     -- 495
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=8, @WeekEnding=20140817, @DoRefresh=0     -- 496
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=9, @WeekEnding=20140817, @DoRefresh=0     -- 497
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140817, @DoRefresh=0     -- 498
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140817, @DoRefresh=0     -- 499
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140817, @DoRefresh=0     -- 500
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=14, @WeekEnding=20140817, @DoRefresh=0     -- 501
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140817, @DoRefresh=0     -- 502
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=16, @WeekEnding=20140817, @DoRefresh=0     -- 503
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140817, @DoRefresh=0     -- 504
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140817, @DoRefresh=0     -- 505
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140817, @DoRefresh=0     -- 506
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140817, @DoRefresh=0     -- 507
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=32, @WeekEnding=20140817, @DoRefresh=0     -- 508
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=40, @WeekEnding=20140817, @DoRefresh=0     -- 509
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140817, @DoRefresh=0     -- 510
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140817, @DoRefresh=0     -- 511
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=53, @WeekEnding=20140817, @DoRefresh=0     -- 512
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=60, @WeekEnding=20140817, @DoRefresh=0     -- 513
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140817, @DoRefresh=0     -- 514
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=101, @WeekEnding=20140817, @DoRefresh=0     -- 515
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=411, @WeekEnding=20140817, @DoRefresh=0     -- 516
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=412, @WeekEnding=20140817, @DoRefresh=0     -- 517
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=413, @WeekEnding=20140817, @DoRefresh=0     -- 518
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140817, @DoRefresh=0     -- 519
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=699, @WeekEnding=20140817, @DoRefresh=0     -- 520
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=820, @WeekEnding=20140817, @DoRefresh=0     -- 521
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4101, @WeekEnding=20140817, @DoRefresh=0     -- 522
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4102, @WeekEnding=20140817, @DoRefresh=0     -- 523
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=10233, @WeekEnding=20140817, @DoRefresh=0     -- 524
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11003, @WeekEnding=20140817, @DoRefresh=0     -- 525
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52605, @WeekEnding=20140817, @DoRefresh=0     -- 526
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52606, @WeekEnding=20140817, @DoRefresh=0     -- 527
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52607, @WeekEnding=20140817, @DoRefresh=0     -- 528
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52608, @WeekEnding=20140817, @DoRefresh=0     -- 529
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52609, @WeekEnding=20140817, @DoRefresh=0     -- 530
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=77133, @WeekEnding=20140817, @DoRefresh=0     -- 531
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=93426, @WeekEnding=20140817, @DoRefresh=0     -- 532
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140824, @DoRefresh=0     -- 533
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140824, @DoRefresh=0     -- 534
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140824, @DoRefresh=0     -- 535
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140824, @DoRefresh=0     -- 536
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=8, @WeekEnding=20140824, @DoRefresh=0     -- 537
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=9, @WeekEnding=20140824, @DoRefresh=0     -- 538
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140824, @DoRefresh=0     -- 539
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140824, @DoRefresh=0     -- 540
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140824, @DoRefresh=0     -- 541
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=14, @WeekEnding=20140824, @DoRefresh=0     -- 542
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140824, @DoRefresh=0     -- 543
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=16, @WeekEnding=20140824, @DoRefresh=0     -- 544
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140824, @DoRefresh=0     -- 545
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140824, @DoRefresh=0     -- 546
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140824, @DoRefresh=0     -- 547
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140824, @DoRefresh=0     -- 548
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=32, @WeekEnding=20140824, @DoRefresh=0     -- 549
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=40, @WeekEnding=20140824, @DoRefresh=0     -- 550
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140824, @DoRefresh=0     -- 551
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140824, @DoRefresh=0     -- 552
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=53, @WeekEnding=20140824, @DoRefresh=0     -- 553
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=60, @WeekEnding=20140824, @DoRefresh=0     -- 554
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140824, @DoRefresh=0     -- 555
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=101, @WeekEnding=20140824, @DoRefresh=0     -- 556
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=380, @WeekEnding=20140824, @DoRefresh=0     -- 557
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=411, @WeekEnding=20140824, @DoRefresh=0     -- 558
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=412, @WeekEnding=20140824, @DoRefresh=0     -- 559
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=413, @WeekEnding=20140824, @DoRefresh=0     -- 560
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140824, @DoRefresh=0     -- 561
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=660, @WeekEnding=20140824, @DoRefresh=0     -- 562
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=699, @WeekEnding=20140824, @DoRefresh=0     -- 563
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=826, @WeekEnding=20140824, @DoRefresh=0     -- 564
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=827, @WeekEnding=20140824, @DoRefresh=0     -- 565
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4101, @WeekEnding=20140824, @DoRefresh=0     -- 566
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=4102, @WeekEnding=20140824, @DoRefresh=0     -- 567
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=10932, @WeekEnding=20140824, @DoRefresh=0     -- 568
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11250, @WeekEnding=20140824, @DoRefresh=0     -- 569
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=16640, @WeekEnding=20140824, @DoRefresh=0     -- 570
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52610, @WeekEnding=20140824, @DoRefresh=0     -- 571
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52611, @WeekEnding=20140824, @DoRefresh=0     -- 572
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52612, @WeekEnding=20140824, @DoRefresh=0     -- 573
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52613, @WeekEnding=20140824, @DoRefresh=0     -- 574
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52614, @WeekEnding=20140824, @DoRefresh=0     -- 575
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140831, @DoRefresh=0     -- 576
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140831, @DoRefresh=0     -- 577
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140831, @DoRefresh=0     -- 578
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140831, @DoRefresh=0     -- 579
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=8, @WeekEnding=20140831, @DoRefresh=0     -- 580
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140831, @DoRefresh=0     -- 581
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140831, @DoRefresh=0     -- 582
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140831, @DoRefresh=0     -- 583
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=14, @WeekEnding=20140831, @DoRefresh=0     -- 584
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140831, @DoRefresh=0     -- 585
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=16, @WeekEnding=20140831, @DoRefresh=0     -- 586
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140831, @DoRefresh=0     -- 587
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140831, @DoRefresh=0     -- 588
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140831, @DoRefresh=0     -- 589
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140831, @DoRefresh=0     -- 590
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=32, @WeekEnding=20140831, @DoRefresh=0     -- 591
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=40, @WeekEnding=20140831, @DoRefresh=0     -- 592
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140831, @DoRefresh=0     -- 593
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140831, @DoRefresh=0     -- 594
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=60, @WeekEnding=20140831, @DoRefresh=0     -- 595
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140831, @DoRefresh=0     -- 596
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=101, @WeekEnding=20140831, @DoRefresh=0     -- 597
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=380, @WeekEnding=20140831, @DoRefresh=0     -- 598
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=410, @WeekEnding=20140831, @DoRefresh=0     -- 599
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=411, @WeekEnding=20140831, @DoRefresh=0     -- 600
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=412, @WeekEnding=20140831, @DoRefresh=0     -- 601
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=413, @WeekEnding=20140831, @DoRefresh=0     -- 602
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140831, @DoRefresh=0     -- 603
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=660, @WeekEnding=20140831, @DoRefresh=0     -- 604
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=699, @WeekEnding=20140831, @DoRefresh=0     -- 605
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=903, @WeekEnding=20140831, @DoRefresh=0     -- 606
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=904, @WeekEnding=20140831, @DoRefresh=0     -- 607
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=10408, @WeekEnding=20140831, @DoRefresh=0     -- 608
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=10954, @WeekEnding=20140831, @DoRefresh=0     -- 609
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52615, @WeekEnding=20140831, @DoRefresh=0     -- 610
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52616, @WeekEnding=20140831, @DoRefresh=0     -- 611
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52617, @WeekEnding=20140831, @DoRefresh=0     -- 612
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52618, @WeekEnding=20140831, @DoRefresh=0     -- 613
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52619, @WeekEnding=20140831, @DoRefresh=0     -- 614
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=95345, @WeekEnding=20140831, @DoRefresh=0     -- 615
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140907, @DoRefresh=0     -- 616
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140907, @DoRefresh=0     -- 617
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140907, @DoRefresh=0     -- 618
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140907, @DoRefresh=0     -- 619
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=8, @WeekEnding=20140907, @DoRefresh=0     -- 620
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=9, @WeekEnding=20140907, @DoRefresh=0     -- 621
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140907, @DoRefresh=0     -- 622
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140907, @DoRefresh=0     -- 623
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140907, @DoRefresh=0     -- 624
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=14, @WeekEnding=20140907, @DoRefresh=0     -- 625
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140907, @DoRefresh=0     -- 626
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=16, @WeekEnding=20140907, @DoRefresh=0     -- 627
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140907, @DoRefresh=0     -- 628
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140907, @DoRefresh=0     -- 629
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140907, @DoRefresh=0     -- 630
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=21, @WeekEnding=20140907, @DoRefresh=0     -- 631
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140907, @DoRefresh=0     -- 632
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=40, @WeekEnding=20140907, @DoRefresh=0     -- 633
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140907, @DoRefresh=0     -- 634
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140907, @DoRefresh=0     -- 635
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=60, @WeekEnding=20140907, @DoRefresh=0     -- 636
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140907, @DoRefresh=0     -- 637
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=101, @WeekEnding=20140907, @DoRefresh=0     -- 638
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=380, @WeekEnding=20140907, @DoRefresh=0     -- 639
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=410, @WeekEnding=20140907, @DoRefresh=0     -- 640
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=411, @WeekEnding=20140907, @DoRefresh=0     -- 641
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=412, @WeekEnding=20140907, @DoRefresh=0     -- 642
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=413, @WeekEnding=20140907, @DoRefresh=0     -- 643
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140907, @DoRefresh=0     -- 644
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=699, @WeekEnding=20140907, @DoRefresh=0     -- 645
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=910, @WeekEnding=20140907, @DoRefresh=0     -- 646
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11022, @WeekEnding=20140907, @DoRefresh=0     -- 647
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11140, @WeekEnding=20140907, @DoRefresh=0     -- 648
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=30079, @WeekEnding=20140907, @DoRefresh=0     -- 649
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52620, @WeekEnding=20140907, @DoRefresh=0     -- 650
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52621, @WeekEnding=20140907, @DoRefresh=0     -- 651
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52622, @WeekEnding=20140907, @DoRefresh=0     -- 652
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52623, @WeekEnding=20140907, @DoRefresh=0     -- 653
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52624, @WeekEnding=20140907, @DoRefresh=0     -- 654
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140914, @DoRefresh=0     -- 655
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140914, @DoRefresh=0     -- 656
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140914, @DoRefresh=0     -- 657
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140914, @DoRefresh=0     -- 658
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140914, @DoRefresh=0     -- 659
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140914, @DoRefresh=0     -- 660
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140914, @DoRefresh=0     -- 661
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=14, @WeekEnding=20140914, @DoRefresh=0     -- 662
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140914, @DoRefresh=0     -- 663
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=16, @WeekEnding=20140914, @DoRefresh=0     -- 664
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140914, @DoRefresh=0     -- 665
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140914, @DoRefresh=0     -- 666
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140914, @DoRefresh=0     -- 667
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=21, @WeekEnding=20140914, @DoRefresh=0     -- 668
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140914, @DoRefresh=0     -- 669
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=32, @WeekEnding=20140914, @DoRefresh=0     -- 670
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=40, @WeekEnding=20140914, @DoRefresh=0     -- 671
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140914, @DoRefresh=0     -- 672
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140914, @DoRefresh=0     -- 673
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=60, @WeekEnding=20140914, @DoRefresh=0     -- 674
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140914, @DoRefresh=0     -- 675
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=101, @WeekEnding=20140914, @DoRefresh=0     -- 676
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=410, @WeekEnding=20140914, @DoRefresh=0     -- 677
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=411, @WeekEnding=20140914, @DoRefresh=0     -- 678
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=412, @WeekEnding=20140914, @DoRefresh=0     -- 679
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=413, @WeekEnding=20140914, @DoRefresh=0     -- 680
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140914, @DoRefresh=0     -- 681
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=699, @WeekEnding=20140914, @DoRefresh=0     -- 682
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=917, @WeekEnding=20140914, @DoRefresh=0     -- 683
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=2014, @WeekEnding=20140914, @DoRefresh=0     -- 684
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=10445, @WeekEnding=20140914, @DoRefresh=0     -- 685
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11003, @WeekEnding=20140914, @DoRefresh=0     -- 686
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52625, @WeekEnding=20140914, @DoRefresh=0     -- 687
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52626, @WeekEnding=20140914, @DoRefresh=0     -- 688
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52627, @WeekEnding=20140914, @DoRefresh=0     -- 689
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52628, @WeekEnding=20140914, @DoRefresh=0     -- 690
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52629, @WeekEnding=20140914, @DoRefresh=0     -- 691
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140921, @DoRefresh=0     -- 692
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140921, @DoRefresh=0     -- 693
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140921, @DoRefresh=0     -- 694
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140921, @DoRefresh=0     -- 695
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140921, @DoRefresh=0     -- 696
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140921, @DoRefresh=0     -- 697
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140921, @DoRefresh=0     -- 698
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=14, @WeekEnding=20140921, @DoRefresh=0     -- 699
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140921, @DoRefresh=0     -- 700
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=16, @WeekEnding=20140921, @DoRefresh=0     -- 701
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140921, @DoRefresh=0     -- 702
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140921, @DoRefresh=0     -- 703
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140921, @DoRefresh=0     -- 704
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=21, @WeekEnding=20140921, @DoRefresh=0     -- 705
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140921, @DoRefresh=0     -- 706
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=40, @WeekEnding=20140921, @DoRefresh=0     -- 707
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140921, @DoRefresh=0     -- 708
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=60, @WeekEnding=20140921, @DoRefresh=0     -- 709
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140921, @DoRefresh=0     -- 710
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=101, @WeekEnding=20140921, @DoRefresh=0     -- 711
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=380, @WeekEnding=20140921, @DoRefresh=0     -- 712
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=410, @WeekEnding=20140921, @DoRefresh=0     -- 713
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=411, @WeekEnding=20140921, @DoRefresh=0     -- 714
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=412, @WeekEnding=20140921, @DoRefresh=0     -- 715
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=413, @WeekEnding=20140921, @DoRefresh=0     -- 716
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140921, @DoRefresh=0     -- 717
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=660, @WeekEnding=20140921, @DoRefresh=0     -- 718
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=699, @WeekEnding=20140921, @DoRefresh=0     -- 719
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=924, @WeekEnding=20140921, @DoRefresh=0     -- 720
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=925, @WeekEnding=20140921, @DoRefresh=0     -- 721
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=10432, @WeekEnding=20140921, @DoRefresh=0     -- 722
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=10918, @WeekEnding=20140921, @DoRefresh=0     -- 723
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52630, @WeekEnding=20140921, @DoRefresh=0     -- 724
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52631, @WeekEnding=20140921, @DoRefresh=0     -- 725
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52632, @WeekEnding=20140921, @DoRefresh=0     -- 726
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52633, @WeekEnding=20140921, @DoRefresh=0     -- 727
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52634, @WeekEnding=20140921, @DoRefresh=0     -- 728
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=92201, @WeekEnding=20140921, @DoRefresh=0     -- 729
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140928, @DoRefresh=0     -- 730
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140928, @DoRefresh=0     -- 731
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140928, @DoRefresh=0     -- 732
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140928, @DoRefresh=0     -- 733
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140928, @DoRefresh=0     -- 734
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140928, @DoRefresh=0     -- 735
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140928, @DoRefresh=0     -- 736
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=14, @WeekEnding=20140928, @DoRefresh=0     -- 737
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140928, @DoRefresh=0     -- 738
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=16, @WeekEnding=20140928, @DoRefresh=0     -- 739
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140928, @DoRefresh=0     -- 740
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140928, @DoRefresh=0     -- 741
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140928, @DoRefresh=0     -- 742
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=21, @WeekEnding=20140928, @DoRefresh=0     -- 743
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140928, @DoRefresh=0     -- 744
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=32, @WeekEnding=20140928, @DoRefresh=0     -- 745
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=40, @WeekEnding=20140928, @DoRefresh=0     -- 746
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140928, @DoRefresh=0     -- 747
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=60, @WeekEnding=20140928, @DoRefresh=0     -- 748
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140928, @DoRefresh=0     -- 749
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=101, @WeekEnding=20140928, @DoRefresh=0     -- 750
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=410, @WeekEnding=20140928, @DoRefresh=0     -- 751
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=411, @WeekEnding=20140928, @DoRefresh=0     -- 752
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=412, @WeekEnding=20140928, @DoRefresh=0     -- 753
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=413, @WeekEnding=20140928, @DoRefresh=0     -- 754
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=414, @WeekEnding=20140928, @DoRefresh=0     -- 755
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140928, @DoRefresh=0     -- 756
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=660, @WeekEnding=20140928, @DoRefresh=0     -- 757
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=699, @WeekEnding=20140928, @DoRefresh=0     -- 758
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=1001, @WeekEnding=20140928, @DoRefresh=0     -- 759
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=10344, @WeekEnding=20140928, @DoRefresh=0     -- 760
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=10944, @WeekEnding=20140928, @DoRefresh=0     -- 761
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52635, @WeekEnding=20140928, @DoRefresh=0     -- 762
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52636, @WeekEnding=20140928, @DoRefresh=0     -- 763
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52637, @WeekEnding=20140928, @DoRefresh=0     -- 764
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52638, @WeekEnding=20140928, @DoRefresh=0     -- 765
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=52639, @WeekEnding=20140928, @DoRefresh=0     -- 766
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=53028, @WeekEnding=20140928, @DoRefresh=0     -- 767
go
exec mspGetCgcPayrollBatch @CompanyNumber=1, @BatchNumber=93001, @WeekEnding=20140928, @DoRefresh=0     -- 768
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140511, @DoRefresh=0     -- 769
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140511, @DoRefresh=0     -- 770
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140518, @DoRefresh=0     -- 771
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=25, @WeekEnding=20140518, @DoRefresh=0     -- 772
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140518, @DoRefresh=0     -- 773
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=30, @WeekEnding=20140518, @DoRefresh=0     -- 774
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=35, @WeekEnding=20140518, @DoRefresh=0     -- 775
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=10953, @WeekEnding=20140518, @DoRefresh=0     -- 776
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=11209, @WeekEnding=20140518, @DoRefresh=0     -- 777
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140601, @DoRefresh=0     -- 778
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=25, @WeekEnding=20140601, @DoRefresh=0     -- 779
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140601, @DoRefresh=0     -- 780
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=30, @WeekEnding=20140601, @DoRefresh=0     -- 781
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=35, @WeekEnding=20140601, @DoRefresh=0     -- 782
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=100, @WeekEnding=20140601, @DoRefresh=0     -- 783
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=603, @WeekEnding=20140601, @DoRefresh=0     -- 784
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=11119, @WeekEnding=20140601, @DoRefresh=0     -- 785
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=11242, @WeekEnding=20140601, @DoRefresh=0     -- 786
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140608, @DoRefresh=0     -- 787
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=25, @WeekEnding=20140608, @DoRefresh=0     -- 788
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140608, @DoRefresh=0     -- 789
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=30, @WeekEnding=20140608, @DoRefresh=0     -- 790
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=35, @WeekEnding=20140608, @DoRefresh=0     -- 791
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=100, @WeekEnding=20140608, @DoRefresh=0     -- 792
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=611, @WeekEnding=20140608, @DoRefresh=0     -- 793
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=11028, @WeekEnding=20140608, @DoRefresh=0     -- 794
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=11223, @WeekEnding=20140608, @DoRefresh=0     -- 795
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140615, @DoRefresh=0     -- 796
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=25, @WeekEnding=20140615, @DoRefresh=0     -- 797
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140615, @DoRefresh=0     -- 798
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=30, @WeekEnding=20140615, @DoRefresh=0     -- 799
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=35, @WeekEnding=20140615, @DoRefresh=0     -- 800
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=100, @WeekEnding=20140615, @DoRefresh=0     -- 801
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=618, @WeekEnding=20140615, @DoRefresh=0     -- 802
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=10156, @WeekEnding=20140615, @DoRefresh=0     -- 803
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=10946, @WeekEnding=20140615, @DoRefresh=0     -- 804
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140629, @DoRefresh=0     -- 805
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=25, @WeekEnding=20140629, @DoRefresh=0     -- 806
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140629, @DoRefresh=0     -- 807
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=30, @WeekEnding=20140629, @DoRefresh=0     -- 808
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=35, @WeekEnding=20140629, @DoRefresh=0     -- 809
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=100, @WeekEnding=20140629, @DoRefresh=0     -- 810
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=701, @WeekEnding=20140629, @DoRefresh=0     -- 811
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=10922, @WeekEnding=20140629, @DoRefresh=0     -- 812
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=11033, @WeekEnding=20140629, @DoRefresh=0     -- 813
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140706, @DoRefresh=0     -- 814
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=25, @WeekEnding=20140706, @DoRefresh=0     -- 815
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140706, @DoRefresh=0     -- 816
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=30, @WeekEnding=20140706, @DoRefresh=0     -- 817
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=35, @WeekEnding=20140706, @DoRefresh=0     -- 818
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=100, @WeekEnding=20140706, @DoRefresh=0     -- 819
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=709, @WeekEnding=20140706, @DoRefresh=0     -- 820
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=11107, @WeekEnding=20140706, @DoRefresh=0     -- 821
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=11249, @WeekEnding=20140706, @DoRefresh=0     -- 822
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=33488, @WeekEnding=20140706, @DoRefresh=0     -- 823
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140713, @DoRefresh=0     -- 824
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=25, @WeekEnding=20140713, @DoRefresh=0     -- 825
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140713, @DoRefresh=0     -- 826
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=30, @WeekEnding=20140713, @DoRefresh=0     -- 827
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=35, @WeekEnding=20140713, @DoRefresh=0     -- 828
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=100, @WeekEnding=20140713, @DoRefresh=0     -- 829
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=715, @WeekEnding=20140713, @DoRefresh=0     -- 830
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=10922, @WeekEnding=20140713, @DoRefresh=0     -- 831
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=10953, @WeekEnding=20140713, @DoRefresh=0     -- 832
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140720, @DoRefresh=0     -- 833
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=25, @WeekEnding=20140720, @DoRefresh=0     -- 834
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140720, @DoRefresh=0     -- 835
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=30, @WeekEnding=20140720, @DoRefresh=0     -- 836
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=35, @WeekEnding=20140720, @DoRefresh=0     -- 837
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=100, @WeekEnding=20140720, @DoRefresh=0     -- 838
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=716, @WeekEnding=20140720, @DoRefresh=0     -- 839
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=10219, @WeekEnding=20140720, @DoRefresh=0     -- 840
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=11035, @WeekEnding=20140720, @DoRefresh=0     -- 841
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140727, @DoRefresh=0     -- 842
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=25, @WeekEnding=20140727, @DoRefresh=0     -- 843
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140727, @DoRefresh=0     -- 844
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=30, @WeekEnding=20140727, @DoRefresh=0     -- 845
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=35, @WeekEnding=20140727, @DoRefresh=0     -- 846
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=100, @WeekEnding=20140727, @DoRefresh=0     -- 847
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=730, @WeekEnding=20140727, @DoRefresh=0     -- 848
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=10945, @WeekEnding=20140727, @DoRefresh=0     -- 849
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=11206, @WeekEnding=20140727, @DoRefresh=0     -- 850
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140803, @DoRefresh=0     -- 851
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=25, @WeekEnding=20140803, @DoRefresh=0     -- 852
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140803, @DoRefresh=0     -- 853
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=30, @WeekEnding=20140803, @DoRefresh=0     -- 854
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=35, @WeekEnding=20140803, @DoRefresh=0     -- 855
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=100, @WeekEnding=20140803, @DoRefresh=0     -- 856
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=806, @WeekEnding=20140803, @DoRefresh=0     -- 857
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=11014, @WeekEnding=20140803, @DoRefresh=0     -- 858
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=11138, @WeekEnding=20140803, @DoRefresh=0     -- 859
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140810, @DoRefresh=0     -- 860
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=25, @WeekEnding=20140810, @DoRefresh=0     -- 861
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140810, @DoRefresh=0     -- 862
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=30, @WeekEnding=20140810, @DoRefresh=0     -- 863
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=35, @WeekEnding=20140810, @DoRefresh=0     -- 864
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=100, @WeekEnding=20140810, @DoRefresh=0     -- 865
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=10948, @WeekEnding=20140810, @DoRefresh=0     -- 866
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=11241, @WeekEnding=20140810, @DoRefresh=0     -- 867
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=56354, @WeekEnding=20140810, @DoRefresh=0     -- 868
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140817, @DoRefresh=0     -- 869
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=25, @WeekEnding=20140817, @DoRefresh=0     -- 870
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140817, @DoRefresh=0     -- 871
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=30, @WeekEnding=20140817, @DoRefresh=0     -- 872
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=35, @WeekEnding=20140817, @DoRefresh=0     -- 873
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=100, @WeekEnding=20140817, @DoRefresh=0     -- 874
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=820, @WeekEnding=20140817, @DoRefresh=0     -- 875
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=10233, @WeekEnding=20140817, @DoRefresh=0     -- 876
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=11003, @WeekEnding=20140817, @DoRefresh=0     -- 877
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140824, @DoRefresh=0     -- 878
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=25, @WeekEnding=20140824, @DoRefresh=0     -- 879
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140824, @DoRefresh=0     -- 880
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=30, @WeekEnding=20140824, @DoRefresh=0     -- 881
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=35, @WeekEnding=20140824, @DoRefresh=0     -- 882
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=100, @WeekEnding=20140824, @DoRefresh=0     -- 883
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=827, @WeekEnding=20140824, @DoRefresh=0     -- 884
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=10932, @WeekEnding=20140824, @DoRefresh=0     -- 885
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=11250, @WeekEnding=20140824, @DoRefresh=0     -- 886
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140831, @DoRefresh=0     -- 887
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=25, @WeekEnding=20140831, @DoRefresh=0     -- 888
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140831, @DoRefresh=0     -- 889
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=30, @WeekEnding=20140831, @DoRefresh=0     -- 890
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=35, @WeekEnding=20140831, @DoRefresh=0     -- 891
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=100, @WeekEnding=20140831, @DoRefresh=0     -- 892
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=903, @WeekEnding=20140831, @DoRefresh=0     -- 893
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=10408, @WeekEnding=20140831, @DoRefresh=0     -- 894
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=10954, @WeekEnding=20140831, @DoRefresh=0     -- 895
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140907, @DoRefresh=0     -- 896
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=25, @WeekEnding=20140907, @DoRefresh=0     -- 897
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140907, @DoRefresh=0     -- 898
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=30, @WeekEnding=20140907, @DoRefresh=0     -- 899
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=35, @WeekEnding=20140907, @DoRefresh=0     -- 900
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=100, @WeekEnding=20140907, @DoRefresh=0     -- 901
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=910, @WeekEnding=20140907, @DoRefresh=0     -- 902
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=11022, @WeekEnding=20140907, @DoRefresh=0     -- 903
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=11140, @WeekEnding=20140907, @DoRefresh=0     -- 904
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140914, @DoRefresh=0     -- 905
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=25, @WeekEnding=20140914, @DoRefresh=0     -- 906
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140914, @DoRefresh=0     -- 907
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=27, @WeekEnding=20140914, @DoRefresh=0     -- 908
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=30, @WeekEnding=20140914, @DoRefresh=0     -- 909
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=35, @WeekEnding=20140914, @DoRefresh=0     -- 910
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=100, @WeekEnding=20140914, @DoRefresh=0     -- 911
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=917, @WeekEnding=20140914, @DoRefresh=0     -- 912
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=10445, @WeekEnding=20140914, @DoRefresh=0     -- 913
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=11003, @WeekEnding=20140914, @DoRefresh=0     -- 914
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140921, @DoRefresh=0     -- 915
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=25, @WeekEnding=20140921, @DoRefresh=0     -- 916
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140921, @DoRefresh=0     -- 917
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=27, @WeekEnding=20140921, @DoRefresh=0     -- 918
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=30, @WeekEnding=20140921, @DoRefresh=0     -- 919
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=35, @WeekEnding=20140921, @DoRefresh=0     -- 920
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=100, @WeekEnding=20140921, @DoRefresh=0     -- 921
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=924, @WeekEnding=20140921, @DoRefresh=0     -- 922
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=10432, @WeekEnding=20140921, @DoRefresh=0     -- 923
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=10918, @WeekEnding=20140921, @DoRefresh=0     -- 924
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140928, @DoRefresh=0     -- 925
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=25, @WeekEnding=20140928, @DoRefresh=0     -- 926
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140928, @DoRefresh=0     -- 927
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=27, @WeekEnding=20140928, @DoRefresh=0     -- 928
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=30, @WeekEnding=20140928, @DoRefresh=0     -- 929
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=35, @WeekEnding=20140928, @DoRefresh=0     -- 930
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=36, @WeekEnding=20140928, @DoRefresh=0     -- 931
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=100, @WeekEnding=20140928, @DoRefresh=0     -- 932
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=1001, @WeekEnding=20140928, @DoRefresh=0     -- 933
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=10344, @WeekEnding=20140928, @DoRefresh=0     -- 934
go
exec mspGetCgcPayrollBatch @CompanyNumber=20, @BatchNumber=10944, @WeekEnding=20140928, @DoRefresh=0     -- 935
go


SELECT * FROM dbo.cgcPayrollBatchForVPImport WHERE PREndDate='9/28/2014'