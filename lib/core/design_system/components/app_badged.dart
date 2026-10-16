import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// [child] with a [badge] on its bottom end corner, overlapping its edge,
/// like a camera on a profile photo or a tick on a picked card. The badge
/// takes no room of its own: the pair is the size of [child], and measures
/// as [child] does.
class AppBadged extends MultiChildRenderObjectWidget {
  AppBadged({super.key, required Widget child, required Widget badge})
    : super(children: [child, badge]);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderBadged(Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderBadged).direction = Directionality.of(context);
  }
}

class _BadgedParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderBadged extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _BadgedParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _BadgedParentData> {
  _RenderBadged(this._direction);

  TextDirection _direction;
  set direction(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! _BadgedParentData) {
      child.parentData = _BadgedParentData();
    }
  }

  RenderBox? get _child => firstChild;
  RenderBox? get _badge => lastChild == firstChild ? null : lastChild;

  @override
  double computeMinIntrinsicWidth(double height) =>
      _child?.getMinIntrinsicWidth(height) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _child?.getMaxIntrinsicWidth(height) ?? 0;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _child?.getMinIntrinsicHeight(width) ?? 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _child?.getMaxIntrinsicHeight(width) ?? 0;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _child?.getDryLayout(constraints) ?? constraints.smallest;

  @override
  void performLayout() {
    final child = _child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    size = child.size;
    final badge = _badge;
    if (badge == null) return;
    badge.layout(BoxConstraints.loose(size), parentUsesSize: true);
    (badge.parentData! as _BadgedParentData).offset = Offset(
      _direction == TextDirection.rtl ? 0 : size.width - badge.size.width,
      size.height - badge.size.height,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
