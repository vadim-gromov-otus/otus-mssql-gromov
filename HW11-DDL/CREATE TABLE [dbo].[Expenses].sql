USE [HomeBookkeeping]
GO

/****** Object:  Table [dbo].[Expenses]    Script Date: 08.09.2024 23:16:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Expenses](
	[ExpensesID] [int] NOT NULL,
	[SubjectID] [int] NOT NULL,
	[TypeExpenses] [int] NOT NULL,
	[Summ] [money] NOT NULL,
	[Date] [date] NOT NULL,
 CONSTRAINT [PK_Expenses] PRIMARY KEY CLUSTERED 
(
	[ExpensesID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Expenses]  WITH CHECK ADD  CONSTRAINT [FK_Expenses_Subject] FOREIGN KEY([SubjectID])
REFERENCES [dbo].[Subject] ([SubjectID])
GO

ALTER TABLE [dbo].[Expenses] CHECK CONSTRAINT [FK_Expenses_Subject]
GO

ALTER TABLE [dbo].[Expenses]  WITH CHECK ADD  CONSTRAINT [FK_Expenses_TypeExpenses] FOREIGN KEY([TypeExpenses])
REFERENCES [dbo].[TypeExpenses] ([TypeID])
GO

ALTER TABLE [dbo].[Expenses] CHECK CONSTRAINT [FK_Expenses_TypeExpenses]
GO

ALTER TABLE [dbo].[Expenses]  WITH CHECK ADD  CONSTRAINT [CK_Expenses] CHECK  (([summ]<(0)))
GO

ALTER TABLE [dbo].[Expenses] CHECK CONSTRAINT [CK_Expenses]
GO


