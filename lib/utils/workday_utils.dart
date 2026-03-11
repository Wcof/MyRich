class WorkdayUtils {
  static bool isWorkday(DateTime date) {
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return false;
    }
    
    return true;
  }

  static bool isAfterWorkday(DateTime transactionDate, DateTime currentDate) {
    if (transactionDate.year == currentDate.year &&
        transactionDate.month == currentDate.month &&
        transactionDate.day == currentDate.day) {
      return false;
    }

    DateTime checkDate = DateTime(transactionDate.year, transactionDate.month, transactionDate.day);
    DateTime endDate = DateTime(currentDate.year, currentDate.month, currentDate.day);
    
    int workdaysPassed = 0;
    checkDate = checkDate.add(const Duration(days: 1));
    
    while (checkDate.isBefore(endDate) || checkDate.isAtSameMomentAs(endDate)) {
      if (isWorkday(checkDate)) {
        workdaysPassed++;
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }

    return workdaysPassed >= 1;
  }

  static bool shouldConfirmTransaction(DateTime transactionDate, DateTime currentDate) {
    final transactionHour = transactionDate.hour;
    
    if (transactionHour >= 15) {
      DateTime nextWorkday = transactionDate.add(const Duration(days: 1));
      while (!isWorkday(nextWorkday)) {
        nextWorkday = nextWorkday.add(const Duration(days: 1));
      }
      
      return currentDate.isAfter(nextWorkday) || 
             (currentDate.year == nextWorkday.year &&
              currentDate.month == nextWorkday.month &&
              currentDate.day == nextWorkday.day);
    } else {
      if (isWorkday(transactionDate)) {
        DateTime endOfDay = DateTime(transactionDate.year, transactionDate.month, transactionDate.day, 15, 0);
        if (currentDate.isAfter(endOfDay)) {
          return true;
        }
      }
      
      return isAfterWorkday(transactionDate, currentDate);
    }
  }
}
