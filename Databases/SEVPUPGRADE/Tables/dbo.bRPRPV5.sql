CREATE TABLE [dbo].[bRPRPV5]
(
[Title] [char] (40) COLLATE Latin1_General_BIN NOT NULL,
[ParameterName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[DisplaySeq] [tinyint] NOT NULL,
[DataType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[BidtekType] [char] (30) COLLATE Latin1_General_BIN NULL,
[Description] [varchar] (1000) COLLATE Latin1_General_BIN NULL,
[ParameterDefault] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[F4Lookup] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[InputType] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[InputMask] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[InputLength] [tinyint] NULL,
[Prec] [tinyint] NULL
) ON [PRIMARY]
GO
