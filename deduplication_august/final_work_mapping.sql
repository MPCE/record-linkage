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
-- Table structure for table `final_work_mapping`
--

DROP TABLE IF EXISTS `final_work_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `final_work_mapping` (
  `id_1` char(12) DEFAULT NULL,
  `id_2` char(12) DEFAULT NULL,
  KEY `map` (`id_2`,`id_1`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `final_work_mapping`
--

LOCK TABLES `final_work_mapping` WRITE;
/*!40000 ALTER TABLE `final_work_mapping` DISABLE KEYS */;
INSERT INTO `final_work_mapping` VALUES ('spbk0002575','spbk0000667'),('spbk0003404','spbk0001299'),('zspbk0013145','spbk00014802'),('spbk0004806','spbk00014869'),('spbk0001839','spbk00014871'),('spbk0003304','spbk00014919'),('spbk0001182','spbk00014976'),('spbk00014784','spbk00014985'),('zspbk0012749','spbk00014996'),('spbk0002101','spbk0002098'),('spbk0002433','spbk0002438'),('zspbk0012525','spbk0003583'),('spbk0003752','spbk0003751'),('spbk0004746','spbk0010363'),('spbk0010299','spbk0010476'),('zspbk0013512','zspbk0010573'),('spbk0001810','zspbk0010621'),('zspbk0013769','zspbk0010691'),('zspbk0014178','zspbk0010766'),('zspbk0011178','zspbk0010994'),('spbk0000565','zspbk0011019'),('zspbk0011246','zspbk0011337'),('spbk0004995','zspbk0011379'),('zspbk0011445','zspbk0011446'),('spbk0000372','zspbk0011492'),('zspbk0011601','zspbk0011602'),('zspbk0010718','zspbk0011624'),('zspbk0011763','zspbk0011684'),('spbk0000520','zspbk0011718'),('spbk0002700','zspbk0011755'),('spbk0003763','zspbk0011765'),('zspbk0011922','zspbk0011774'),('spbk0002759','zspbk0011843'),('zspbk0013915','zspbk0011942'),('zspbk0011961','zspbk0011962'),('zspbk0011344','zspbk0011968'),('zspbk0011824','zspbk0011983'),('spbk0000788','zspbk0011994'),('zspbk0011617','zspbk0012031'),('zspbk0012054','zspbk0012055'),('zspbk0012090','zspbk0012091'),('zspbk0014101','zspbk0012298'),('zspbk0012316','zspbk0012317'),('spbk0003842','zspbk0012377'),('zspbk0011712','zspbk0012523'),('spbk0001162','zspbk0012568'),('zspbk0012575','zspbk0012576'),('spbk00014830','zspbk0012588'),('zspbk0012741','zspbk0012742'),('spbk0000429','zspbk0012801'),('zspbk0012617','zspbk0012832'),('zspbk0012850','zspbk0012851'),('spbk0002596','zspbk0012946'),('spbk0001148','zspbk0013065'),('zspbk0013107','zspbk0013108'),('spbk0002190','zspbk0013155'),('zspbk0013172','zspbk0013171'),('zspbk0013218','zspbk0013219'),('zspbk0013235','zspbk0013233'),('zspbk0013233','zspbk0013234'),('zspbk0013235','zspbk0013234'),('zspbk0012923','zspbk0013290'),('zspbk0012247','zspbk0013318'),('spbk0000451','zspbk0013327'),('zspbk0013962','zspbk0013344'),('zspbk0013204','zspbk0013363'),('zspbk0010883','zspbk0013369'),('zspbk0011656','zspbk0013375'),('zspbk0012699','zspbk0013433'),('zspbk0012745','zspbk0013452'),('spbk0004753','zspbk0013581'),('spbk0004387','zspbk0013632'),('zspbk0011901','zspbk0013652'),('spbk00014914','zspbk0013653'),('zspbk0013658','zspbk0013659'),('zspbk0013679','zspbk0013680'),('zspbk0011848','zspbk0013708'),('zspbk0011402','zspbk0013712'),('spbk0001851','zspbk0013730'),('zspbk0012546','zspbk0013765'),('zspbk0011714','zspbk0013795'),('zspbk0011937','zspbk0013810'),('zspbk0013846','zspbk0013847'),('zspbk0013846','zspbk0013848'),('zspbk0010698','zspbk0013853'),('zspbk0010902','zspbk0013874'),('zspbk0013195','zspbk0013913'),('zspbk0013693','zspbk0013938'),('spbk0000053','zspbk0013944'),('zspbk0012551','zspbk0013961'),('zspbk0013198','zspbk0013967'),('zspbk0011520','zspbk0014003'),('zspbk0014747','zspbk0014182'),('zspbk0014199','zspbk0014200'),('zspbk0011561','zspbk0014282'),('zspbk0014679','zspbk0014294'),('zspbk0012341','zspbk0014317'),('zspbk0011417','zspbk0014323'),('zspbk0014172','zspbk0014427'),('zspbk0014437','zspbk0014438'),('zspbk0014502','zspbk0014501'),('zspbk0014601','zspbk0014517'),('zspbk0014126','zspbk0014549'),('zspbk0014602','zspbk0014593'),('zspbk0013278','zspbk0014600'),('zspbk0014259','zspbk0014686'),('zspbk0014688','zspbk0014687'),('zspbk0014251','zspbk0014750');
/*!40000 ALTER TABLE `final_work_mapping` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2019-08-14 11:32:08
