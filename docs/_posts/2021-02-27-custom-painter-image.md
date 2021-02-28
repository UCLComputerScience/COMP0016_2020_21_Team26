---
layout: post
author: Chris Tomy
title: Circular Progress with an Image, using Custom Painter
---

# Introduction

This post will explain how I implemented a widget that displays some fraction
visually in a circle, using an image as a marker for the end point.
Correctly transforming/resizing/rotating the image was the main challenge, which
I will describe.

Here's a quick sketch of my goal:

![Circle with percentage in middle.](https://uclcomputerscience.github.io/COMP0016_2020_21_Team26/images/UI_First.png)

The stick man represents the image. So as the goal/progress changes, the 
circular progress changes as well. (I'm being intentionally generic in what the
progress is actually for. This will allow us to reuse it if needed.)

## Without CustomPainter?

It might be possible to do this without a CustomPainter, instead just carefully
laying and positioning widgets on top of each other, but CustomPainter is better designed
for controlling the size of what we ultimately want to create.

## Prerequisites

I assume knowledge of Flutter, Dart & *basic* knowledge of working with CustomPainter,
i.e. you have watched [this 5 minute video](https://www.youtube.com/watch?v=vvI_NUXK00s&feature=emb_title).

# General Approach

The idea would be to 
1. draw two circles with different radii $r_1$ and $r_2$, $r_1 > r_2$
about some center point $(x, y)$. They should have different colors.
2. draw an arc (or circle sector) about $(x, y)$ with angle $progress*2\pi$ radians 
and radius $r_1$. This should have another color.
3. assuming the image is already correctly sized, rotate it $-1*progress*2\pi$. This
is negative because the circle/progress increases anticlockwise.
4. place the image at $((r_1+r_2)/2, -1*progress*2\pi)$ in polar coordinates, 
about $(x,y)$ and with the polar axis pointing upwards.

I use radians for all angles.

# Implementation

Time to implement this in Flutter/Dart. Since I'm only using it to demonstrate
the user's progress on a step goal I'll call my new class `StepGoalPainter`.
It would be easy to refactor/rename if needed. Here's the main structure of the class:

``` dart
import 'dart:ui' as ui;

class StepGoalPainter extends CustomPainter {
    final double completed;
    final ui.Image marker;
    
    StepGoalPainter(this.completed, this.marker);
    
    @override
    void paint(ui.Canvas canvas, ui.Size size) {
        // TODO: implement paint
    }
    
    @override
    bool shouldRepaint(StepGoalPainter old) {
        // TODO: implement shouldRepaint
    }
}
```

Here I'm subclassing CustomPainter and also expecting two arguments to determine 
the paint. `completed` should be a fraction, and `marker` will be the image.
I'm using a stateless & declarative style, i.e. painting based on the current 
given 'state' (`completed`), rather than retrieving it in this class.
Note that I'm using a named import to avoid conflicting with other definition(s)
of an `Image` (e.g. from `widgets` library).

The `paint` function is the main part of the class, but let's finish the easy one,
`shouldRepaint`.

``` dart
    @override
    bool shouldRepaint(StepGoalPainter old) {
        return completed != old.completed || marker != oldDelegate.marker;
    }
```

This tells flutter when to repaint, and more importantly, when *not* to. This
should help flutter optimize repaints.

Now, let's add steps 1 & 2 to `paint`:
``` dart
    @override
    void paint(ui.Canvas canvas, ui.Size size) {
        // the size we have to paint on should be finite so we can determine
        // the center point to draw from:
        assert(size.isFinite);
        // sanity check to ensure we're given a valid double:
        assert(!completed.isNaN)
        
        Offset center = size.center(Offset.zero);
        // this ensures we're working with a fraction
        final fraction = completed.clamp(0, 1);
        final radius = size.shortestSide / 2; // this is r_1
        final innerRadius = radius * 0.8; // r_2
        
        // setting up some colors
        final outerPaint = Paint()
            ..style = PaintingStyle.fill
            ..color = Colors.grey.shade200;
        final innerPaint = Paint()
            ..style = PaintingStyle.fill
            ..color = Colors.purpleAccent;
        final midPaint = Paint()
            ..style = PaintingStyle.fill
            ..color = Colors.white;
        
        
        // outer circle of radius r_1:
        canvas.drawCircle(center, radius, outerPaint);
        // arc of radius r_1:
        canvas.drawArc(
            // drawArc uses a rectangle to determine the position of the arc:
            Rect.fromCenter(center: center, width: size.width, height: size.height),
            0.75 * 2 * pi, // start point is the upper axis
            -fraction * 2 * pi, // theta
            true, // make it a circle sector
            innerPaint);
        canvas.drawCircle(center, innerRadius, midPaint);

        // TODO: resize, rotate, translate and draw the image here
    }
```

Note that generally, *order matters* when using any method on `canvas`.
So drawing the arc after the circle will place the arc on top of the circle.

``` dart
    @override
    void paint(ui.Canvas canvas, ui.Size size) {
        // draw circles and arc here, as shown above
        // ...
        
        // Dealing with the image:
        //
        // target determines the resize. 0.15 means width of image will be 15% of the 
        // of the canvas width:
        final target = 0.15; 
        final c = (target * size.width) / marker.width;
        // the middle of both the previous radii:
        final midRadius = (radius + innerRadius) / 2; 

        // values to translate by, to get image onto the middle stripe
        double x, y;
        if (completed <= 0.25) {
        // four quadrants
        final theta = completed * 2 * pi;
        x = -midRadius * sin(theta);
        y = -midRadius * cos(theta);
        } else if (completed <= 0.5) {
        final theta = completed * 2 * pi - 0.25 * 2 * pi;
        x = -midRadius * cos(theta);
        y = midRadius * sin(theta);
        } else if (completed <= 0.75) {
        final theta = completed * 2 * pi - 0.5 * 2 * pi;
        x = midRadius * sin(theta);
        y = midRadius * cos(theta);
        } else {
        final theta = completed * 2 * pi - 0.75 * 2 * pi;
        x = midRadius * cos(theta);
        y = -midRadius * sin(theta);
        }

        final imageOffset = center
                .scale(1 / c, 1 / c)
                .translate(-marker.width / 2, -marker.height / 2) +
            Offset(x, y).scale(1 / c, 1 / c);

        canvas.scale(c);
        canvas.translate(
            imageOffset.dx + marker.width / 2, imageOffset.dy + marker.height / 2);
        canvas.rotate(-2 * completed * pi);
        canvas.translate(-imageOffset.dx - marker.width / 2,
            -imageOffset.dy - marker.height / 2);
        canvas.drawImage(marker, imageOffset, Paint());
    }
```
