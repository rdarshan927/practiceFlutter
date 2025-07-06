import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class TodoTile extends StatelessWidget {
  final String taskName;
  final bool taskCompleted;
  final Function(bool?)? onChanged;
  final Function(BuildContext)? deleteFunction;

  const TodoTile({
    super.key,
    required this.taskName,
    required this.taskCompleted,
    required this.onChanged,
    required this.deleteFunction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: deleteFunction,
              icon: Icons.delete_outline,
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              borderRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.all(8),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Checkbox(
              value: taskCompleted,
              onChanged: onChanged,
              activeColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            title: Text(
              taskName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                decoration: taskCompleted ? TextDecoration.lineThrough : null,
                color: taskCompleted 
                    ? Colors.grey.shade500 
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            trailing: Icon(
              Icons.drag_handle,
              color: Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }
}
