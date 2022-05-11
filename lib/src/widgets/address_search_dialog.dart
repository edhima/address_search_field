import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:address_search_field/src/enums/address_id.dart';
import 'package:address_search_field/src/models/address.dart';
import 'package:address_search_field/src/notifiers/route_notifier.dart';
import 'package:address_search_field/src/services/geo_methods.dart';

/// Callback method.
typedef OnDoneCallback = FutureOr<void> Function(Address address);

typedef BuilderCallback = Widget Function(
  BuildContext context,
  AsyncSnapshot<List<Address>> snapshot,
  Future<void> Function() searchAddress,
  Future<Address> Function(Address address) getGeometry,
  void Function() dismiss,
);

class AddressDialogStyle {
  const AddressDialogStyle({
    this.color = Colors.blue,
    this.backgroundColor = Colors.white,
    this.useButtons = true,
  });

  /// Color for details in the widget.
  final Color color;

  /// Background color for widget.
  final Color backgroundColor;

  /// Sets if the [AddressDialog] will have buttons at bottom.
  final bool useButtons;
}

class AddressDialogTexts {
  const AddressDialogTexts({
    this.hintText = 'Address or reference',
    this.noResultsText = "There're no results",
    this.continueText = 'Continue',
    this.cancelText = 'Cancel',
  });

  /// Message to show when the [TextField] of the widget is empty.
  final String hintText;

  /// Message to show when the [ListView] of the widget is empty.
  final String noResultsText;

  /// Text for [ElevatedButton] of the widget to continue.
  final String continueText;

  /// Text for [ElevatedButton] of the widget to cancel.
  final String cancelText;
}

class AddressSearchDialog extends ConsumerStatefulWidget {
  AddressSearchDialog({
    required this.geoMethods,
    TextEditingController? controller,
    this.style = const AddressDialogStyle(),
    this.texts = const AddressDialogTexts(),
    this.onDone,
    Key? key,
  })  : _controller = controller ?? TextEditingController(),
        builder = null,
        provider = null,
        addressId = null,
        super(key: key);

  AddressSearchDialog.withProvider({
    required this.provider,
    required this.addressId,
    this.style = const AddressDialogStyle(),
    this.texts = const AddressDialogTexts(),
    this.onDone,
    Key? key,
  })  : _controller = TextEditingController(),
        builder = null,
        geoMethods = null,
        super(key: key);

  AddressSearchDialog.custom({
    required this.geoMethods,
    required this.builder,
    Key? key,
  })  : _controller = TextEditingController(),
        style = const AddressDialogStyle(),
        texts = const AddressDialogTexts(),
        onDone = null,
        provider = null,
        addressId = null,
        super(key: key);

  AddressSearchDialog.customWithProvider({
    required this.builder,
    required this.provider,
    required this.addressId,
    Key? key,
  })  : _controller = TextEditingController(),
        style = const AddressDialogStyle(),
        texts = const AddressDialogTexts(),
        onDone = null,
        geoMethods = null,
        super(key: key);

  /// [GeoMethods] instance to use Google APIs.
  final GeoMethods? geoMethods;

  final BuilderCallback? builder;

  final ChangeNotifierProvider<RouteNotifier>? provider;

  final AddressId? addressId;

  /// controller for text used to search an [Address].
  final TextEditingController _controller;

  final AddressDialogStyle style;

  final AddressDialogTexts texts;

  /// Variable for [AddressDialog].
  final OnDoneCallback? onDone;

  @override
  ConsumerState<AddressSearchDialog> createState() =>
      _AddressSearchDialogState();
}

class _AddressSearchDialogState extends ConsumerState<AddressSearchDialog> {
  /// Representation of the most recent interaction with an asynchronous computation.
  AsyncSnapshot<List<Address>> _snapshot =
      const AsyncSnapshot<List<Address>>.nothing();

  late final TextEditingController _controller;

  late final GeoMethods _geoMethods;

  @override
  void initState() {
    super.initState();
    if (widget.provider != null && widget.addressId != null) {
      if (widget.addressId == AddressId.origin) {
        _controller = ref.read(widget.provider!).originController;
      }
      if (widget.addressId == AddressId.destination) {
        _controller = ref.read(widget.provider!).destinationController;
      }
      _geoMethods = ref.read(widget.provider!).geoMethods;
    } else {
      _controller = widget._controller;
      _geoMethods = widget.geoMethods!;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.builder != null) {
      return widget.builder!(
        context,
        _snapshot,
        _searchAddress,
        _getGeometry,
        _dismiss,
      );
    }
    return _DefaultDialog(
      _controller,
      widget.style,
      widget.texts,
      _snapshot,
      _searchAddress,
      _onSelected,
      _dismiss,
    );
  }

  /// Closes itself.
  void _dismiss() {
    Navigator.pop(context);
    FocusScope.of(context).unfocus();
  }

  /// Loads a list of found addresses by the text in [widget.controller].
  Future<void> _searchAddress() async {
    if (mounted) {
      setState(() => _snapshot = const AsyncSnapshot<List<Address>>.waiting());
    }
    final List<Address> data =
        await _geoMethods.autocompletePlace(query: _controller.text);
    if (mounted) {
      setState(() => _snapshot = (data.isEmpty)
          ? AsyncSnapshot<List<Address>>.withError(
              ConnectionState.done, ArgumentError('Data not found'))
          : AsyncSnapshot<List<Address>>.withData(ConnectionState.done, data));
    }
  }

  /// Tries to get a completed [Address] object by a reference or place id.
  Future<Address> _getGeometry(Address addressRef) async {
    final Address? addressFound = await _geoMethods.getPlaceGeometry(
      reference: addressRef.reference,
      placeId: addressRef.placeId!,
    );
    final addressResult = addressFound ?? addressRef;
    if (widget.provider != null && widget.addressId != null) {
      ref.read(widget.provider!).setLocation(widget.addressId!, addressResult);
    }
    return addressResult;
  }

  /// Selects an [Address] to work.
  Future<void> _onSelected({Address? addressRef}) async {
    late final Address address;
    if (addressRef == null) {
      address = Address.fromReference(reference: _controller.text);
    } else {
      address = await _getGeometry(addressRef);
    }
    if (address.hasReference && _controller.text != address.reference) {
      _controller.text = address.reference!;
    }
    if (widget.onDone != null) {
      await widget.onDone!(address);
    }
    _dismiss();
  }
}

class _DefaultDialog extends StatelessWidget {
  const _DefaultDialog(
    this.controller,
    this.style,
    this.texts,
    this.snapshot,
    this.searchAddress,
    this.onSelected,
    this.dismiss, {
    Key? key,
  }) : super(key: key);

  final TextEditingController controller;

  final AddressDialogStyle style;

  final AddressDialogTexts texts;

  final AsyncSnapshot<List<Address>> snapshot;

  final Future<void> Function() searchAddress;

  final Future<void> Function({Address? addressRef}) onSelected;

  final void Function() dismiss;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final size = Size(
          constraints.constrainWidth(),
          constraints.constrainHeight(),
        );
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SearchBar(
                  size,
                  controller,
                  style.color,
                  style.backgroundColor,
                  texts.hintText,
                  searchAddress,
                ),
                SizedBox(
                  width: size.width * 0.8,
                  child: const Divider(
                    color: Colors.grey,
                    height: 0.2,
                  ),
                ),
                _ResultsList(
                  size,
                  style.backgroundColor,
                  snapshot,
                  style.useButtons,
                  texts.noResultsText,
                  onSelected,
                ),
                (style.useButtons)
                    ? SizedBox(
                        width: size.width * 0.8,
                        child: const Divider(color: Colors.grey, height: 0.2),
                      )
                    : Container(),
                (style.useButtons)
                    ? _DialogButtons(
                        size,
                        style.color,
                        style.backgroundColor,
                        style.useButtons,
                        texts.continueText,
                        texts.cancelText,
                        onSelected,
                        dismiss,
                      )
                    : Container(),
              ],
            ),
          ),
        );
      },
    );
  }
}

typedef SearchAddressCallback = Future<void> Function();

class _SearchBar extends StatelessWidget {
  const _SearchBar(
    this.size,
    this.controller,
    this.color,
    this.backgroundColor,
    this.hintText,
    this.searchAddress, {
    Key? key,
  }) : super(key: key);

  final Size size;

  /// controller for text used to search an [Address].
  final TextEditingController controller;

  /// Color for details in the widget.
  final Color? color;

  /// Bakcground color for widget.
  final Color backgroundColor;

  /// Message to show when the [TextField] of the widget is empty.
  final String hintText;

  final SearchAddressCallback searchAddress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55.0,
      width: size.width * 0.8,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10.0),
          topRight: Radius.circular(10.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Padding(
            padding:
                EdgeInsets.only(left: (size.width * 0.8) * 0.03125), // 0.03125
            child: const Icon(
              Icons.location_city,
              // size: (size.width * 0.8) * 0.0625,
            ),
          ),
          SizedBox(
            width: (size.width * 0.8) * 0.72,
            child: TextField(
              controller: controller,
              autofocus: true,
              autocorrect: false,
              textCapitalization: TextCapitalization.words,
              cursorColor: color ?? Theme.of(context).primaryColor,
              onEditingComplete: searchAddress,
              decoration: InputDecoration(
                suffix: GestureDetector(
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5.0),
                    child: Icon(
                      Icons.close,
                      color: Colors.grey,
                      size: 13.0,
                    ),
                  ),
                  onTap: controller.clear,
                ),
                hintText: hintText,
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: color ?? Theme.of(context).primaryColor),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: color ?? Theme.of(context).primaryColor),
                ),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: color ?? Theme.of(context).primaryColor),
                ),
              ),
            ),
          ),
          GestureDetector(
            child: Padding(
              padding: EdgeInsets.only(
                  right: (size.width * 0.8) * 0.0425), // 0.03125
              child: Icon(
                Icons.search_rounded,
                color: color ?? Theme.of(context).primaryColor,
                // size: (size.width * 0.8) * 0.0625,
              ),
            ),
            onTap: searchAddress,
          )
        ],
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList(
    this.size,
    this.backgroundColor,
    this.snapshot,
    this.useButtons,
    this.noResultsText,
    this.onSelected, {
    Key? key,
  }) : super(key: key);

  final Size size;

  /// Bakcground color for
  final Color backgroundColor;

  /// Representation of the most recent interaction with an asynchronous computation.
  final AsyncSnapshot<List<Address>> snapshot;

  /// Sets if the [AddressDialog] will have buttons at bottom.
  final bool useButtons;

  /// Message to show when the [ListView] of the widget is empty.
  final String noResultsText;

  final Future<void> Function({Address? addressRef}) onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size.height * 0.35,
      width: size.width * 0.8,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: (useButtons)
            ? const BorderRadius.all(Radius.zero)
            : const BorderRadius.only(
                bottomLeft: Radius.circular(10.0),
                bottomRight: Radius.circular(10.0),
              ),
      ),
      child: Center(
        child: (snapshot.connectionState == ConnectionState.waiting)
            ? const CircularProgressIndicator()
            : (snapshot.hasData)
                ? ListView.separated(
                    itemCount: snapshot.data!.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const Divider(),
                    itemBuilder: (BuildContext context, int index) => ListTile(
                      title: Text(snapshot.data![index].reference!),
                      onTap: () async =>
                          await onSelected(addressRef: snapshot.data![index]),
                    ),
                  )
                : Text(
                    noResultsText,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
      ),
    );
  }
}

class _DialogButtons extends StatelessWidget {
  const _DialogButtons(
    this.size,
    this.color,
    this.backgroundColor,
    this.useButtons,
    this.continueText,
    this.cancelText,
    this.onSelected,
    this.dismiss, {
    Key? key,
  }) : super(key: key);

  final Size size;

  /// Bakcground color for
  final Color color;

  /// Bakcground color for
  final Color backgroundColor;

  /// Sets if the [AddressDialog] will have buttons at bottom.
  final bool useButtons;

  /// Message to show when the [ListView] of the widget is empty.
  final String continueText;

  /// Message to show when the [ListView] of the widget is empty.
  final String cancelText;

  final Future<void> Function() onSelected;

  final void Function() dismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      width: size.width * 0.8,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10.0),
          bottomRight: Radius.circular(10.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: GestureDetector(
              child: Text(
                cancelText,
                style: TextStyle(color: color),
              ),
              onTap: () => dismiss(), //context
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              child: Text(
                continueText,
                style: TextStyle(color: color),
              ),
              onTap: () async => await onSelected(),
            ),
          ),
        ],
      ),
    );
  }
}
