import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold/features/lay_out/view_model/lay_out_cubit.dart';
import 'package:gold/features/lay_out/view_model/lay_out_states.dart';
import 'package:material_ui/material_ui.dart';

// ignore: must_be_immutable
class LayOutScreen extends StatelessWidget {
  const LayOutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var layOutCubit = LayOutCubit.get(context);

    return BlocConsumer<LayOutCubit,LayOutStates>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.flash_on,
                        color: Colors.black,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Aurum',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: const [
                          CircleAvatar(
                            radius: 4,
                            backgroundColor: Colors.amber,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(
                        'https://i.imgur.com/BoN9kdC.png',
                      ), // صورة افتراضية للمستخدم
                    ),
                  ],
                ),
              ],
            ),
          ),
          body: layOutCubit.screens[layOutCubit.screensIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: layOutCubit.screensIndex,
            onTap: (value) {
              layOutCubit.changeScreen(value);
            },
            backgroundColor: const Color(0xFF121215),
            selectedItemColor: const Color(0xFFFFD700),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.show_chart),
                label: 'Chart',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet),
                label: 'Portfolio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
