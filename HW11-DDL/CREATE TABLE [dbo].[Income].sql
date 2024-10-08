USE [HomeBookkeeping]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Income](
	[IncomeID] [int] IDENTITY(1,1) NOT NULL,
	[SubjectID] [int] NULL,
	[Type] [nchar](10) NULL,
	[Summ] [money] NULL,
	[Date] [date] NULL,
 CONSTRAINT [PK_Income] PRIMARY KEY CLUSTERED 
(
	[IncomeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Income]  WITH CHECK ADD  CONSTRAINT [FK_Income_Subject] FOREIGN KEY([SubjectID])
REFERENCES [dbo].[Subject] ([SubjectID])
GO

ALTER TABLE [dbo].[Income] CHECK CONSTRAINT [FK_Income_Subject]
GO

ALTER TABLE [dbo].[Income]  WITH CHECK ADD  CONSTRAINT [CK_Income] CHECK  (([summ]>(0)))
GO

ALTER TABLE [dbo].[Income] CHECK CONSTRAINT [CK_Income]
GO


