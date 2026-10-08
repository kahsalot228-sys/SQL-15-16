/*
    Домашнее задание — уроки 15–16
    Тема: сравнение выполнения SELECT до и после создания кластерного индекса.
    СУБД: Microsoft SQL Server

    ВАЖНО:
    1) Выберите свою учебную базу данных в SSMS.
    2) Выполните скрипт целиком (F5).
    3) Включите Actual Execution Plan: Ctrl+M, затем выполните запросы.
    4) Сравните сообщения STATISTICS IO/TIME и планы выполнения.
    5) В комментариях внизу скрипта запишите фактические результаты СВОЕГО запуска.
       Числа зависят от версии SQL Server, кэша, оборудования и настроек.
*/

SET NOCOUNT ON;
GO

-- Создаём отдельную таблицу-эксперимент. При повторном запуске удаляем её.
DROP TABLE IF EXISTS dbo.IndexPerformanceDemo;
GO

-- Таблица намеренно создаётся без индексов (heap).
CREATE TABLE dbo.IndexPerformanceDemo
(
    RowID INT NOT NULL,
    SearchValue INT NOT NULL,
    Payload CHAR(100) NOT NULL
);
GO

-- Генерируем ровно 1 000 000 строк (10 цифрных наборов по 10 значений).
-- SearchValue принимает значения от 1 до 1 000 000.
;WITH
D(n) AS
(
    SELECT n
    FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS v(n)
),
Numbers AS
(
    SELECT
        1
        + d1.n
        + d2.n * 10
        + d3.n * 100
        + d4.n * 1000
        + d5.n * 10000
        + d6.n * 100000 AS NumberValue
    FROM D AS d1
    CROSS JOIN D AS d2
    CROSS JOIN D AS d3
    CROSS JOIN D AS d4
    CROSS JOIN D AS d5
    CROSS JOIN D AS d6
)
INSERT INTO dbo.IndexPerformanceDemo (RowID, SearchValue, Payload)
SELECT
    NumberValue,
    NumberValue,
    REPLICATE('X', 100)
FROM Numbers;
GO

-- Проверяем количество строк: должно быть 1 000 000.
SELECT COUNT(*) AS TotalRows
FROM dbo.IndexPerformanceDemo;
GO

/*
    ЭТАП 1. SELECT ДО СОЗДАНИЯ ИНДЕКСА
    Ожидаемо: SQL Server обычно читает таблицу целиком (Table Scan).
    Запомните logical reads, CPU time, elapsed time и план выполнения.
*/
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

SELECT RowID, SearchValue, Payload
FROM dbo.IndexPerformanceDemo
WHERE SearchValue = 987654;
GO

/*
    ЭТАП 2. СОЗДАЁМ КЛАСТЕРНЫЙ ИНДЕКС
    Кластерный индекс упорядочивает строки таблицы по SearchValue.
    Значения SearchValue уникальны в созданных данных.
*/
CREATE CLUSTERED INDEX CX_IndexPerformanceDemo_SearchValue
ON dbo.IndexPerformanceDemo (SearchValue);
GO

/*
    ЭТАП 3. ПОВТОРЯЕМ ТОТ ЖЕ SELECT ПОСЛЕ ИНДЕКСА
    Ожидаемо: Index Seek вместо Table Scan; прочитанных страниц обычно меньше.
    Запишите новые logical reads, CPU time, elapsed time и план выполнения.
*/
SELECT RowID, SearchValue, Payload
FROM dbo.IndexPerformanceDemo
WHERE SearchValue = 987654;
GO

-- Дополнительная проверка: несколько значений и агрегат.
SELECT SearchValue, RowID
FROM dbo.IndexPerformanceDemo
WHERE SearchValue BETWEEN 987650 AND 987660
ORDER BY SearchValue;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/*
    РЕЗУЛЬТАТЫ МОЕГО ЗАПУСКА (заполните после выполнения в SSMS):

    До индекса:
      План выполнения:
      Logical reads:
      CPU time:
      Elapsed time:

    После кластерного индекса:
      План выполнения:
      Logical reads:
      CPU time:
      Elapsed time:

    Сравнение:
      До индекса обычно выполняется Table Scan — для поиска SQL Server
      проверяет много страниц таблицы.
      После индекса обычно выполняется Clustered Index Seek — SQL Server
      переходит к нужному диапазону B-tree. Для точного поиска обычно
      требуется значительно меньше logical reads.

    Не вписывайте придуманные числа: скопируйте фактические значения из вкладки
    Messages и сравните планы во вкладке Execution Plan.
*/
