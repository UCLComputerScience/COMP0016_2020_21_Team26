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
progress is actually for. We'll just need a fraction to do this.)

# Without CustomPainter?

It might be possible to do this without a CustomPainter, instead just carefully
laying and positioning widgets on top of each other, but CustomPainter is better designed
for controlling the size of what we ultimately want to create.

# General Approach

The idea would be to 
- draw two circles with different radii $r_1$ and $r_2$, $r_1 > r_2$
about some center point $(x, y)$. They should have different colors.
- draw an arc (or circle sector) about $(x, y)$ with angle $progress*2\pi$ radians 
and radius $r_1$. This should have another color.
- assuming the image is already correctly sized, rotate it $-1*progress*2\pi$. This
is negative because the circle progress increases to the left.
