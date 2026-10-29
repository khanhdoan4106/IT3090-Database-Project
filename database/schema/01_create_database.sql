/* =====================================================================
   01_create_database.sql
   Drops and recreates the project database QuanLyTheVeDienTu.
   WARNING: all existing data in QuanLyTheVeDienTu is deleted.
   ===================================================================== */

USE master;
GO

IF DB_ID(N'QuanLyTheVeDienTu') IS NOT NULL
BEGIN
    ALTER DATABASE QuanLyTheVeDienTu SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE QuanLyTheVeDienTu;
END
GO

CREATE DATABASE QuanLyTheVeDienTu;
GO
