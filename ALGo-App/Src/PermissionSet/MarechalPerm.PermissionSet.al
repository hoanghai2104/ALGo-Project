permissionset 50100 MarechalPerm
{
    Assignable = true;
    Permissions =
      tabledata RplpParametrage = RIMD,
      tabledata CalculateRPLP = RIMD,
      tabledata SoumissionHeader = RIMD,
      tabledata SoumissionLine = RIMD,
      tabledata SoumissionHeaderArchive = RIMD,
      // tabledata SoumissionLineArchive = RIMD,
      tabledata SoumissionLineArchiveNew = RIMD,
      tabledata DialogExtractSoumissionTemp = R,
      // tabledata ReceptionAchatPM = RIMD
      // tabledata DetailReceptionAchatPM = RIMD,
      tabledata DetailReceptionAchat = RIMD,

      tabledata "Sales/Service Order Buffer" = RIMD,
      table "Sales/Service Order Buffer" = X;
}