import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class CustomerBottomNavBar extends StatelessWidget {
  final BuildContext context;

  const CustomerBottomNavBar({
    super.key,
    required this.context,
  });

  int _getCurrentIndex() {
    final location = GoRouterState.of(context).uri.toString();
    if (location == '/customer' || location == '/customer/') {
      return 0;
    } else if (location.startsWith('/customer/cars')) {
      return 1;
    } else if (location.startsWith('/customer/offers')) {
      return 2;
    } else if (location.startsWith('/customer/chatbot')) {
      return 3;
    } else if (location.startsWith('/customer/profile')) {
      return 4;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _getCurrentIndex(),
      selectedFontSize: 12.sp,
      unselectedFontSize: 10.sp,
      iconSize: 24.sp,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/customer');
            break;
          case 1:
            context.go('/customer/cars');
            break;
          case 2:
            context.go('/customer/offers');
            break;
          case 3:
            context.go('/customer/chatbot');
            break;
          case 4:
            context.go('/customer/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_car),
          label: 'My Cars',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_offer),
          label: 'Offers',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

