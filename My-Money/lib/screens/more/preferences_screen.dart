import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/theme.dart';

import '../../services/ai_coach_service.dart';
import '../ai_coach/ai_coach_screen.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});
  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  AiBackendStatus? _status;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final s = await AiCoachService().checkStatus();
    if (mounted) setState(() => _status = s);
  }

  @override
  Widget build(BuildContext context){
    final p=context.watch<AppProvider>();
    return Scaffold(
      backgroundColor:AppTheme.bgDark,
      appBar:AppBar(title:const Text('Preferences')),
      body:ListView(padding:const EdgeInsets.all(16),children:[
        _Section('PREFERENCES',[
          ListTile(
            leading:const Icon(Icons.palette_outlined,color:AppTheme.primary),
            title:const Text('Theme'),
            subtitle:Text(p.themeMode[0].toUpperCase()+p.themeMode.substring(1),
              style:const TextStyle(color:AppTheme.textSecondary)),
            trailing:SegmentedButton<String>(
              segments:const[
                ButtonSegment(value:'dark',label:Text('Dark',style:TextStyle(fontSize:11))),
                ButtonSegment(value:'light',label:Text('Light',style:TextStyle(fontSize:11))),
                ButtonSegment(value:'auto',label:Text('Auto',style:TextStyle(fontSize:11))),
              ],
              selected:{p.themeMode},
              onSelectionChanged:(s)=>p.setThemeMode(s.first),
              style:ButtonStyle(
                backgroundColor:WidgetStateProperty.resolveWith((states)=>
                  states.contains(WidgetState.selected)
                    ?AppTheme.primary.withOpacity(0.2):Colors.transparent),
                foregroundColor:WidgetStateProperty.resolveWith((states)=>
                  states.contains(WidgetState.selected)
                    ?AppTheme.primary:AppTheme.textSecondary),
              ),
            ),
          ),
        ]),
        const SizedBox(height:16),
        _Section('NOTIFICATIONS',[
          SwitchListTile(
            secondary:const Icon(Icons.notifications_outlined,
              color:AppTheme.primary),
            title:const Text('Budget Alerts'),
            subtitle:const Text('Alert when near budget limit',
              style:TextStyle(color:AppTheme.textSecondary,fontSize:12)),
            value:p.notifBudget,activeColor:AppTheme.primary,
            onChanged:(v)=>p.setNotifications(v,p.notifRecurring)),
          const Divider(indent:56,height:1,color:AppTheme.divider),
          SwitchListTile(
            secondary:const Icon(Icons.repeat,color:AppTheme.primary),
            title:const Text('Recurring Reminders'),
            subtitle:const Text('Remind about recurring transactions',
              style:TextStyle(color:AppTheme.textSecondary,fontSize:12)),
            value:p.notifRecurring,activeColor:AppTheme.primary,
            onChanged:(v)=>p.setNotifications(p.notifBudget,v)),
        ]),
        const SizedBox(height:16),
        _Section('AI FINANCIAL COACH',[
          ListTile(
            leading:const Icon(Icons.auto_awesome,color:AppTheme.primary),
            title:const Text('AI Coach Status'),
            subtitle:Text(
              _status == null
                  ? 'Checking connection...'
                  : _status!.isOnline
                      ? 'Online • ${_status!.provider.toUpperCase()} (${_status!.model})'
                      : 'Offline (run "run_ai_backend.bat")',
              style: TextStyle(
                color: _status?.isOnline == true ? AppTheme.primary : AppTheme.expenseRed,
                fontSize: 12,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.refresh, size: 20, color: AppTheme.primary),
              onPressed: _checkStatus,
            ),
          ),
          const Divider(indent:56,height:1,color:AppTheme.divider),
          ListTile(
            leading:const Icon(Icons.chat_bubble_outline,color:AppTheme.primary),
            title:const Text('Open AI Coach'),
            subtitle:const Text('Chat with your personal finance coach',
              style:TextStyle(color:AppTheme.textSecondary,fontSize:12)),
            trailing:const Icon(Icons.chevron_right,color:AppTheme.textSecondary,size:18),
            onTap:()=>Navigator.push(context,
              MaterialPageRoute(builder:(_)=>const AiCoachScreen())),
          ),
        ]),
      ]));
  }
}

Widget _Section(String title,List<Widget> items)=>Column(
  crossAxisAlignment:CrossAxisAlignment.start,children:[
  Text(title,style:const TextStyle(color:AppTheme.textSecondary,
    fontSize:11,fontWeight:FontWeight.w600)),
  const SizedBox(height:8),
  Container(decoration:BoxDecoration(color:AppTheme.cardDark,
    borderRadius:BorderRadius.circular(14)),
  child:Column(children:items)),
]);
