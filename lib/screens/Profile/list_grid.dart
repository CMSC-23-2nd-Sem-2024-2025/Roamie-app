// Grid builder for the Travel Styles and interest which are the two list string attributes of the user
import 'package:flutter/material.dart';

Widget interestGrid(List<String> interests) {
  return Padding(
    
    padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 0), 
    child: GridView.builder(
      shrinkWrap: true, 
      physics: const NeverScrollableScrollPhysics(),
      itemCount: interests.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2,
      ),
      itemBuilder: (BuildContext context, int index) {
        return Card(
          color: Colors.orange,
          child: Center(
            child: Text(
              interests[index],
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    ),
  );
}

Widget styleGrid(List<String> travelStyles) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 0),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: travelStyles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2,
      ),
      itemBuilder: (BuildContext context, int index) {
        return Card(
          color: const Color(0xFF101653),
          child: Center(
            child: Text(
              travelStyles[index],
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    ),
  );
}

