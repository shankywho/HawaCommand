import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/features/air_map/application/air_map_controller.dart';
import 'package:hawa_app/features/air_map/domain/place.dart';
import 'package:hawa_app/features/shell/domain/app_permission.dart';
import 'package:hawa_app/features/shell/presentation/permission_education_screen.dart';

/// What the search screen hands back to the map.
class PlacePick {
  const PlacePick.place(Place this.place) : pickOnMap = false;

  const PlacePick.onMap() : place = null, pickOnMap = true;

  final Place? place;
  final bool pickOnMap;
}

/// `/map/search?field=from|to`: Google-Maps-style place search with "Your location", "Choose on
/// map" and popular Delhi places.
class PlaceSearchScreen extends ConsumerStatefulWidget {
  const PlaceSearchScreen({required this.isOrigin, super.key});

  final bool isOrigin;

  @override
  ConsumerState<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends ConsumerState<PlaceSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _locating = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  Future<void> _useMyLocation() async {
    final l = context.l10n;
    if (!await ensurePermission(context, ref, AppPermission.location)) return;
    setState(() => _locating = true);
    final point = await ref.read(myLocationProvider.notifier).locate();
    if (!mounted) return;
    setState(() => _locating = false);
    if (point == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.airMapLocationUnavailable)));
      return;
    }
    context.pop(
      PlacePick.place(Place(name: l.airMapYourLocation, point: point, isMyLocation: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final results = _query.length < 2 ? null : ref.watch(placeSearchProvider(_query));
    const popular = DelhiPlaces.landmarks;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: (v) => setState(() => _query = v.trim()),
          decoration: InputDecoration(
            hintText: widget.isOrigin ? l.airMapSearchFrom : l.airMapSearchTo,
            border: InputBorder.none,
            filled: false,
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              tooltip: l.commonClose,
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: ListView(
        children: [
          if (widget.isOrigin)
            ListTile(
              leading: _locating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: Color(0xFF1A73E8)),
              title: Text(l.airMapYourLocation),
              onTap: _locating ? null : _useMyLocation,
            ),
          ListTile(
            leading: const Icon(Icons.pin_drop_outlined),
            title: Text(l.airMapChooseOnMap),
            onTap: () => context.pop(const PlacePick.onMap()),
          ),
          const Divider(),
          if (results == null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                l.airMapPopular,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: c.mutedForeground),
              ),
            ),
            for (final p in popular) _PlaceTile(place: p, icon: Icons.history_toggle_off),
          ] else
            ...results.when(
              loading: () => const [
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (_, _) => [
                Padding(padding: const EdgeInsets.all(16), child: Text(l.airMapSearchOffline)),
                for (final p in DelhiPlaces.search(_query)) _PlaceTile(place: p),
              ],
              data: (list) => list.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(child: Text(l.airMapNoResults)),
                      ),
                    ]
                  : [for (final p in list) _PlaceTile(place: p)],
            ),
        ],
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place, this.icon = Icons.place_outlined});

  final Place place;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: place.subtitle == null
        ? null
        : Text(place.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
    onTap: () => context.pop(PlacePick.place(place)),
  );
}
