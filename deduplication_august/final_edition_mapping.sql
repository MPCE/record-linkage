-- MySQL dump 10.16  Distrib 10.1.34-MariaDB, for Win32 (AMD64)
--
-- Host: localhost    Database: mpce1
-- ------------------------------------------------------
-- Server version	10.1.34-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `final_edition_mapping`
--

DROP TABLE IF EXISTS `final_edition_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `final_edition_mapping` (
  `id_1` char(12) DEFAULT NULL,
  `id_2` char(12) DEFAULT NULL,
  KEY `map` (`id_2`,`id_1`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `final_edition_mapping`
--

LOCK TABLES `final_edition_mapping` WRITE;
/*!40000 ALTER TABLE `final_edition_mapping` DISABLE KEYS */;
INSERT INTO `final_edition_mapping` VALUES ('nbk0011807','nbk0011765'),('nbk0011976','nbk0011975'),('nbk0015171','nbk0011984'),('nbk0014923','nbk0014051'),('nbk0016072','nbk0014437'),('nbk0014566','nbk0014565'),('nbk0014567','nbk0014565'),('nbk0014567','nbk0014566'),('nbk0014606','nbk0014607'),('nbk0017471','nbk0014730'),('nbk0017504','nbk0015200'),('nbk0015460','nbk0015459'),('nbk0018748','nbk0015737'),('nbk0015740','nbk0015739'),('nbk0019403','nbk0016204'),('nbk0016277','nbk0016276'),('nbk0018395','nbk0016451'),('nbk0016627','nbk0016626'),('nbk0016628','nbk0016626'),('nbk0016628','nbk0016627'),('nbk0017110','nbk0017109'),('nbk0017426','nbk0017256'),('nbk0018568','nbk0017560'),('nbk0017686','nbk0017685'),('nbk0017754','nbk0017753'),('nbk0018423','nbk0018422'),('nbk0018530','nbk0018529'),('nbk0018665','nbk0018664'),('nbk0018711','nbk0018684'),('nbk0018820','nbk0018819'),('nbk0019007','nbk0019006'),('nbk0019340','nbk0019205');
/*!40000 ALTER TABLE `final_edition_mapping` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2019-08-14 12:50:51
